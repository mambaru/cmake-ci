#!/bin/bash
export LANG=en_US.UTF-8

defopt="-Wall -Wextra -Wpedantic -Wformat --pedantic-errors"
generator="g++"
specific="warnings"
if [[ $1 == "optimize" ]]; then
  specific="optimize"
  defopt="-O3 -march=native"
  off="--off"
fi


mkdir -p gen
mkdir -p gen/lists
mkdir -p gen/lists/all

# Находим все доступные компиляторы
>/tmp/prefix-list.txt
# Формат "префикс версия путь"
>/tmp/available-compilers.txt


while read -r compiler; do
  #echo $compiler
  [ ! -e "$compiler" ] && continue
  headline=$($compiler --version | head -1)
  version=$(echo "$headline" | egrep -o "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+"| egrep -o "[[:digit:]]+\.[[:digit:]]+" | head -1 )
  prefix=$(echo "$headline" | egrep -o "g\+\+" | head -1)
  [ -z $prefix ] && prefix=$(echo "$headline" | egrep -o "clang" | head -1)
  [ -z $prefix ] && prefix=$(echo "$headline" | cut -f1 -d ' ' | head -1)
  
  #echo $headline
  #echo $version
  #echo $prefix
  
  # список префиксов, например g++ и clang, если новый то очищаем список версий для префикса
  grep -Fxq "$prefix" "/tmp/prefix-list.txt" || ( echo "$prefix" >> "/tmp/prefix-list.txt" && >"/tmp/$prefix-versions.txt" )
  
  # текущаяя макс версия
  toppred=$(cat "/tmp/$prefix-versions.txt" | sort --version-sort | tail -1)
  
  # добавить версию для текущего, если ее нет
  grep -Fxq "$version" "/tmp/$prefix-versions.txt" || \
    ( echo "$version" >> "/tmp/$prefix-versions.txt" && echo "$prefix $version $compiler" >> "/tmp/available-compilers.txt" )
  
  [[ "$prefix" == "g++" ]] && [[ "$toppred" < "$version" ]] && generator="$compiler"
 
done < ./compilers.txt

while read -r compline; do
  prefix=$(echo $compline | cut -f1 -d ' ')
  version=$(echo $compline | cut -f2 -d ' ')
  compiler=$(echo $compline | cut -f3 -d ' ')
  outfile="./gen/lists/all/$specific-$prefix-$version.txt"
  if [[ ! -f "$outfile" ]]; then
    echo "Генерация списка для $prefix-$version"
    ./c++warnings.sh -S $specific -s list -g "$generator $defopt" -t "$compiler $defopt" > $outfile
  fi
done < /tmp/available-compilers.txt


commonf="./gen/lists/$specific-common.txt"
rm -f /tmp/common-options.txt
rm -f $commonf
echo "Общий список опций $commonf"
for curfile in ./gen/lists/all/$specific*; do
  if [[ -f "/tmp/common-options.txt" ]]; then
    sort /tmp/common-options.txt > /tmp/left.txt
    sort $curfile > /tmp/right.txt
    comm -12 /tmp/left.txt /tmp/right.txt > $commonf
    cp -f $commonf /tmp/common-options.txt
  else
    cp $curfile $commonf
    cp $curfile /tmp/common-options.txt
  fi 
done

# список файлов опций включая созданные ранее 
ls ./gen/lists/all/$specific* | egrep -o "\-.*\-" | sort | uniq | tac > /tmp/options-sufixes.txt

while read -r sufix; do
  ls ./gen/lists/all/$specific$sufix* | sort --version-sort > /tmp/$specific${sufix}list.txt
  cp ./gen/lists/$specific-common.txt /tmp/$specific${sufix}common.txt
  while read -r curlst; do
    echo "Уникальные опции для $curlst"
    curname=$(basename $curlst)
    
    sort $curlst > /tmp/left.txt
    sort /tmp/$specific${sufix}common.txt > /tmp/right.txt
    comm -23 /tmp/left.txt /tmp/right.txt > ./gen/lists/$curname
    cat ./gen/lists/$curname >> /tmp/$specific${sufix}common.txt
    
  done < /tmp/$specific${sufix}list.txt
done < /tmp/options-sufixes.txt


#topcheg=$(ls ./gen/lists/all/$specific-g++* | sort --version-sort | tail -1)
topcheg=$(ls ./gen/lists/all/$specific-g++* | sort --version-sort | grep g++ | grep -Ff /tmp/g++-versions.txt  | tail -1)
echo $topcheg
for curlst in ./gen/lists/$specific*; do
  curname=$(basename $curlst | sed 's/txt/cmake/g')
  echo "Генерация cmake для $curname"
  ./c++warnings.sh -S $specific -s cmake -g "$generator" -G $topcheg -T $curlst $off > "./gen/$curname"
done

echo "Генерация общего cmake"
ocmake="./gen/$specific.cmake"
>$ocmake

echo "include(\${CMAKE_CURRENT_LIST_DIR}/$specific-common.cmake)" >> $ocmake
echo "" >> $ocmake
while read -r sufix; do
  if [[ $sufix == "-g++-" ]]; then
    compilerid="GNU"
  elif [[ $sufix == "-clang-" ]]; then
    compilerid="Clang"
  else 
    compilerid="TODO"
  fi
  
  echo "if ( \"\${CMAKE_CXX_COMPILER_ID}\" STREQUAL \"$compilerid\" )" >> $ocmake
    for fcmake in ./gen/$specific$sufix*.cmake; do
      version=$(echo $fcmake | egrep -o "[0-9]+.[0-9]+")
      echo "  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER $version OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL $version )"  >> $ocmake
      echo "    include(\${CMAKE_CURRENT_LIST_DIR}/$(basename $fcmake))"  >> $ocmake
      echo "  endif()"  >> $ocmake
    done
  echo "endif()"  >> $ocmake
  echo "" >> $ocmake
done < /tmp/options-sufixes.txt


#ls ./gen/lists/warning* | sort --version-sort | grep -v common > /tmp/options-files.txt
#cat /tmp/options-files.txt | grep -v common | egrep -o "\-.*\-" | sort | uniq > /tmp/options-sufixes.txt
#cat /tmp/options-sufixes.txt
#cat /tmp/available-compilers.txt




exit 0



defwrn="-Wall -Wextra -Wpedantic -Wformat --pedantic-errors"

find "/usr/bin/" -type f -name g++* | sort --version-sort > /tmp/g++compilers.txt
find "/usr/bin/" -regex '/usr/bin/clang-[0-9]+.[0-9]+' | sort --version-sort > /tmp/clang++compilers.txt

ygpp=$(head -1 /tmp/g++compilers.txt)
yclang=$(head -1 /tmp/clang++compilers.txt)
topgpp=$(tail -1 /tmp/g++compilers.txt)
topclang=$(tail -1 /tmp/clang++compilers.txt)


if [[ $1 == "optimize" ]]; then
  specific="optimize"
  defwrn="-O3"
  off="--off"
fi


function create_list()
{
  flist=$1
  while read -r compiler; do
    name=$(basename $compiler)
    fcur="./gen/lists/$specific-$name.txt"
    if [[ ! -f "$fcur" ]]; then
      echo "Генерация списка для $compiler"
      ./c++warnings.sh -S $specific -s list -g "$topgpp $defwrn" -t "$compiler" > "$fcur"
    fi
  done < $flist
}

function create_cmake()
{
  flist=$1
  cp "/tmp/$specific-c++.txt" "/tmp/current-exclude.txt"
  while read -r fcur; do
    fcmake=$(echo $fcur | sed 's/txt/cmake/g')
    fcmake="./gen/$(basename $fcmake)"
    version=$(echo "$fcur" | egrep -o "[[:digit:]]+\.[[:digit:]]*")
    echo "Генерация cmake для $fcur в $fcmake версия $version"
    fgen="./gen/lists/$specific-$(basename $topgpp).txt"
    ./c++warnings.sh -S $specific -s cmake -g "$topgpp" -G "$fgen" -T "$fcur" -X "/tmp/current-exclude.txt" $off > "$fcmake"
    ./c++warnings.sh -S $specific -s list -g "$topgpp" -G "$fgen" -T "$fcur" -X "/tmp/current-exclude.txt" >> "/tmp/current-exclude.txt"
    
    echo "  if( CMAKE_CXX_COMPILER_VERSION VERSION_GREATER $version OR CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL $version )"  >> $ocmake
    echo "    include(gen/$(basename $fcmake))"  >> $ocmake
    echo "  endif()"  >> $ocmake
  done < $flist
}

create_list /tmp/g++compilers.txt
create_list /tmp/clang++compilers.txt


echo "Генерация общего набора для $ygpp и $yclang с опциями '$defwrn'"
./c++warnings.sh -S $specific -s cmake -g "$topgpp $defwrn" -G "./gen/lists/$specific-$(basename $ygpp).txt" -T "./gen/lists/$specific-$(basename $yclang).txt" $off > "./gen/$specific-c++.cmake"
./c++warnings.sh -S $specific -s list -g "$topgpp $defwrn"  -G "./gen/lists/$specific-$(basename $ygpp).txt" -T "./gen/lists/$specific-$(basename $yclang).txt" > "/tmp/$specific-c++.txt"


find "./gen" -type f -name $specific-g++*.txt | sort --version-sort > /tmp/g++-lists.txt
find "./gen" -type f -name $specific-clang*.txt | sort --version-sort > /tmp/clang-lists.txt

ocmake="./gen/$specific.cmake"
>$ocmake

echo "include(\${CMAKE_CURRENT_LIST_DIR}/$specific-c++.cmake)" >> $ocmake
echo "" >> $ocmake
echo "if ( \"\${CMAKE_CXX_COMPILER_ID}\" STREQUAL \"GNU\" )" >> $ocmake
  create_cmake /tmp/g++-lists.txt
echo "endif()"  >> $ocmake
echo "" >> $ocmake
echo "if ( \"\${CMAKE_CXX_COMPILER_ID}\" STREQUAL \"Clang\" )" >> $ocmake
  create_cmake /tmp/clang-lists.txt
echo "endif()"  >> $ocmake
exit 0
