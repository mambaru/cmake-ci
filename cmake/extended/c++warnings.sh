#!/bin/bash
export LANG=en_US.UTF-8

# Можно передавать  со списком включенных опций "g++ -W -Wall -Wextra -Wpedantic"
#generator="g++-7 -W -Wall -Wextra -Wpedantic"
generator="g++"
generated_file=""
target=""
target_file=""
# исключить опции этого компилятора (по умолчанию "")
exclude=""
exclude_file=""
enabled=false
disabled=false
other=false
verbose=false
# list|brief|desc|cmake
show="desc"
specific="warnings"
defval="ON"

function usage()
{
# -o, --only-matching       показывать только часть строки, совпадающей с ШАБЛОНОМ
  echo "Выводи список опций (предупреждений) отключенных по умолчанию для заданного компилятора. "
  echo "  -g, --generator <<цель>>    [g++] компилятор g++ - генератор опций. По умолчанию генерируются только "
  echo "               отключенные опции. Можно использовать комбинации 'g++ -Wall -Wextra -Wpedantic' для генерации "
  echo "               опций с учетом этих флагов. Нельзя использовать clang++ для генерации опций. " 
  echo "  -G, --generated-file <<file>> "
  echo ""
  echo "  -t, --target <<цель>>    Целевой компилятор для которого генерируются опции. По умолчанию используется"
  echo "               компилятор указанный в опции --generator или g++. В качестве цели допустимо использовать clang++."
  echo "  -T, --target-file <<file>> "
  echo ""
  echo "  -e, --exclude <<цель>>    Компилятор g++ - генератор опций, которые нужно исключить из финального списка"
  echo "               опций. Например '--generator g++ --exclude g++ -Wextra' выдаст список"
  echo "               предупреждений, которые включает для которого генерируются опции. "
  echo "  -X, --exclude-file <<file>> "
  echo ""
  echo "  -E, --enabled    Выводить только включенные опции."
  echo "  -D, --disabled   Выводить также и выключенные опции. Имеет смысл только в комбинации с -E если нужно получить "
  echo "               список включенных и отключенных опций."
  echo "  --other    Выводить остальные опции, которые не имеют статуса [enabled] или [disabled]."
  echo "  -v, --verbose Подробный вывод действий скрипта"

  
  #echo "usage: $0 [[[-f file ] [-i]] | [-h]] $help"
}

function echo_if()
{
  if [[ $verbose = true ]]; then 
    echo "$1"
  fi
}

function test_options()
{
  compiler=$1
  ffrom=$2
  ofile=$3
  >$ofile
  
  [[ -z "$compiler" ]] && return
  echo_if "======= test_options: $compiler ========"
  
  while read -r opt; do
    if [[ $($compiler $opt test.cpp -o /dev/null 2>&1 | wc -l) == "0" ]] ; then 
      echo_if "test ok: $compiler $opt "
      echo "$opt " >> $ofile # пробел чтобы работал шаблон из файла для grep
    else
      echo_if "test error: $compiler $opt "
    fi
  done < $ffrom
}

function create_options()
{
  compiler="$1"
  ofile="$2"
  >$ofile
 
  [[ -z "$compiler" ]] && return
  echo_if "======= create_options: $compiler ========"
  
  # | grep -v "="
  # | grep -v "="
  > /tmp/create_option.txt
  if [[ $enabled = true ]]; then
    echo_if "    create [enabled]"
    $compiler -Q --help=$specific | grep "\[enabled\]"  | awk '{print $1}' | sort >> /tmp/create_option.txt
  fi

  if [[ $disabled = true ]]; then
    echo_if "    create [disabled]"
    $compiler -Q --help=$specific | grep "\[disabled\]" | awk '{print $1}' | sort >> /tmp/create_option.txt
  fi
  
  if [[ $other = true ]]; then
    echo_if "    create [other]"
    $compiler -Q --help=$specific | grep -v "\[enabled\]" | grep -v "\[disabled\]" | awk '{print $1}' | grep . | sort >> /tmp/create_option.txt
  fi
 
 test_options "$compiler" "/tmp/create_option.txt" "$ofile"
}

function intersection_options()
{
  ffrom=$1
  fexcl=$2
  fto=$3
  
  cat $ffrom | sort > /tmp/exclude_from.txt
  cat $fexcl | sort > /tmp/exclude_what.txt
  comm -12 /tmp/exclude_from.txt /tmp/exclude_what.txt > $fto
}


function difference_options()
{
  ffrom=$1
  fexcl=$2
  fto=$3
  
  cat $ffrom | sort > /tmp/exclude_from.txt
  cat $fexcl | sort > /tmp/exclude_what.txt
  comm -23 /tmp/exclude_from.txt /tmp/exclude_what.txt > $fto
}

function show_result()
{
  ffrom=$1
  $generator --help=$specific | grep -Ff $ffrom | sed 's/"/`/g'> /tmp/desc-options.txt
  cat /tmp/desc-options.txt | grep -vF -f ./disabled.txt -f ./enabled.txt | awk '{printf("extended_option(%s \"",$1);for (i=2; i<NF; i++) printf $i " "; printf("%s\" ON)\n",$NF);}' | sed "s/ON/$defval/g"
  cat /tmp/desc-options.txt | grep -Ff ./disabled.txt | grep -vFf ./enabled.txt | awk '{printf("extended_option(%s \"",$1);for (i=2; i<NF; i++) printf $i " "; printf("%s\" OFF)\n",$NF);}'
  cat /tmp/desc-options.txt | grep -Ff ./enabled.txt | grep -vFf ./disabled.txt | awk '{printf("extended_option(%s \"",$1);for (i=2; i<NF; i++) printf $i " "; printf("%s\" ON)\n",$NF);}'
}

##### Main

#[[ ! $1 ]] && usage

while [ "$1" != "" ]; do
  case $1 in
    -g | --generator ) shift
                       generator=$1
                       ;;
    -G | --generated-file ) shift
                            generated_file=$1
                            ;;
    -t | --target ) shift
                    target=$1
                    ;;
    -T | --target-file ) shift
                         target_file=$1
                         ;;
    -e | --exclude ) shift
                     exclude=$1
                     ;;
    -X | --exclude-file ) shift
                         exclude_file=$1
                         ;;
    -E | --enabled ) enabled=true
                     ;;
    -D | --disabled ) disabled=true
                     ;;
    --other ) other=true
              ;;
    --off ) defval="OFF"
            ;;
    -s | --show ) shift
                  show=$1
                  ;;
    -S | --specific) shift
                     specific=$1
                     ;;
    -v | --verbose )  verbose=true
                      ;;
    -h | --help ) usage
                  exit
                  ;;
    * )           usage "Привет"
                  exit 1
  esac
  shift
done

if [[ $enabled = false && $disabled = false && $other = false ]]; then
  enabled=false
  disabled=true
  other=false
fi

[[ -z "$target" ]] && target=$generator

echo_if "generator=$generator"
echo_if "generated_file=$generated_file"
echo_if "target=$target"
echo_if "target_file=$target_file"
echo_if "exclude=$exclude"
echo_if "exclude_file=$exclude_file"
echo_if "enabled=$enabled"
echo_if "disabled=$disabled"
echo_if "other=$other"
echo_if "cmake=$cmake"

#echo_if "======= create generator ========"

if [[ -f "$generated_file" ]] ; then 
  echo_if "cp '$generated_file' /tmp/generate-options.txt"
  cp "$generated_file" "/tmp/generate-options.txt"
else
  create_options "$generator" "/tmp/generate-options.txt"
fi

if [[ -f "$exclude_file" ]] ; then 
  echo_if "cp '$exclude_file' /tmp/exclude-options.txt"
  cp "$exclude_file" "/tmp/exclude-options.txt"
elif [[ $exclude == *"clang"* ]]; then
  test_options "$exclude" "/tmp/generate-options.txt" "/tmp/exclude-options.txt"
else
  create_options "$exclude" "/tmp/exclude-options.txt"  
fi

if [[ -f "$target_file" ]] ; then 
  echo_if "cp '$target_file' /tmp/target-options.txt"
  cp "$target_file" "/tmp/target-options.txt"
elif [[ $target == *"clang"* ]]; then
  test_options "$target" "/tmp/generate-options.txt" "/tmp/target-options.txt"
else
  create_options "$target" "/tmp/target-options.txt"  
fi

intersection_options "/tmp/target-options.txt" "/tmp/generate-options.txt" "/tmp/pre-result-options.txt"
difference_options "/tmp/pre-result-options.txt" "/tmp/exclude-options.txt" "/tmp/result-options.txt"

echo_if "======= result ========"
case $show in
  desc ) $generator --help=$specific | grep -Ff /tmp/result-options.txt
         ;;
  brief ) $generator -Q --help=$specific | grep -Ff /tmp/result-options.txt
         ;;
  list ) $generator -Q --help=$specific | grep -Ff /tmp/result-options.txt | awk '{print $1 " "}' 
         ;;
  cmake ) show_result /tmp/result-options.txt
         ;;
  * ) cat /tmp/result-options.txt
      exit 1
esac

