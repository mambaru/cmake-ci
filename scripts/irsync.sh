#!/bin/bash

# export AUTOSYNC=1 для автоматической синхронизации

irsync=`basename "$0"`
if (( "$#" < 2 )); then
  echo "Usage:"
  echo -e "\t$irsync src dst [orig [tmp] ]"
  exit 0
fi

function interactive_merge () {
  target="${2#*/}" # Путь без головы
  echo "Интерактивное слияние ${target} с помощью sdiff."
  echo "Нажимай:"
  echo -e "1 - оставить твои измениения"
  echo -e "2 - принять новые"
  echo -e "q - прервать"
  echo -e "Enter - дополнительные опции (см. документацию sdiff)"
  sdiff -sw 130 -o "$1.tmp" "$2" "$1"
  if [ $? -eq 2 ]; then
    echo "Отмена! слияния $target"
    rm -f "$1.tmp"
    return 1
  else
    mv "$1.tmp" "$2"
    cp "$2" "$3"
    echo "Слито! $target"
    echo "Файл $target интерактивно слит" >> report.txt
  fi
}

function see_and_merge () {
  target="${2#*/}" # Путь без головы
  if ! diff "$2" "$1"; then
    echo "Выше показаны изменения в обновленном $target относительно твоего."
    case1="Не обновлять. Оставить старый $target (с твоими изменениями)"
    case2="Принять новый $target (с потерей твоих изменений)"
    case3="Интерактивно слить с помощью sdiff"
    case4="Прервать (никакие обновления не будут применены) "

    COLUMNS=12
    select yn in "${case1}" "${case2}" "${case3}" "${case4}"
    do
      case $yn in
        "${case1}" )
            echo "Файл $target оставлены локальные изменения" >> report.txt
            break;;
        "${case2}" )
            cp "$1" "$2"
            cp "$1" "$3"
            echo "Файл $target заменен с потерей изменений" >> report.txt
            break;;
        "${case3}" )
            if interactive_merge $1 $2 $3; then
              cp "$1" "$3"
            else
              return 1
            fi
            break;;
        "${case4}" )
            return 1
            break;;
        * ) echo "Не тупи! 1,2,3 или 4"
      esac
    done
  else
    echo "Файлы $1 в обновлении и локальные идентичны"
    cp "$1" "$3"
  fi
}


function update_or_merge () {
  target="${2#*/}" # Путь без головы

  diff $1 $3

  echo "У мне две новости, дорогой друг. Первая заключается в том что прилетело "
  echo "обновление для $target. Вторая - ты внес в $target некоторые изменения."
  echo "Выше показаны изменения обновления (без учета твоих изменений)."

  case1="Не обновлять. Оставить старый $target (с твоими изменениями)."
  case2="Принять новый $target (с потерей твоих изменений)."
  case3="Посмотреть мои изменения и принять решение."
  case4="Прервать (никакие обновления не будут применены) "

  COLUMNS=12
  select yn in "${case1}" "${case2}" "${case3}" "${case4}"
  do
    case $yn in
      "${case1}" )
          echo "Файл $target оставлены локальные изменения" >> report.txt
          break;;
      "${case2}" )
          echo "Файл $target заменен с потерей изменений" >> report.txt
          cp "$1" "$2"
          cp "$1" "$3"
          break;;
      "${case3}" )
          see_and_merge $1 $2 $3
          return $?
          break;;
      "${case4}" )
          return 1
          break;;
      * ) echo "Не тупи! 1,2 или 3"
    esac
  done
}

src=$1
dst=$2
orig="${3:-$dst}/.orig"
wrk="${4:-$dst}/.wrk"

rm -rf "$wrk/"

wrksrc="$wrk/src"
wrkdst="$wrk/dst"
wrkorig="$wrk/orig"

mkdir -p $orig
mkdir -p $wrksrc
mkdir -p $wrkdst
mkdir -p $wrkorig

rsync -r --exclude ".wrk/" --exclude ".orig/" --exclude "build/" "$src/" "$wrksrc/"
pushd "$wrksrc" > /dev/null
find . -type f -printf '%P\n' > "../src-list.txt"
popd > /dev/null

rsync -r --exclude ".wrk/" --exclude ".orig/" --exclude "build/" "$dst/" "$wrkdst/"
pushd "$wrkdst" > /dev/null
find . -type f -printf '%P\n' > "../dst-list.txt"
popd > /dev/null

rsync -r --exclude ".wrk/" --exclude ".orig/" --exclude "build/" "$orig/" "$wrkorig/"

pushd "$wrk" > /dev/null

rm -f report.txt

IFS=$'\n' read -d '' -r -a lines < src-list.txt

discard=0
for line in "${lines[@]}"
do
  mkdir -p $(dirname dst/$line)
  mkdir -p $(dirname orig/$line)

  if [ ! -e "dst/$line" ]; then
    echo "Прилетел новый файл $line " >> report.txt
    cp "src/$line" "dst/$line"
  elif cmp -s "src/$line" "dst/$line"; then
    echo "Файл $line без обновлений" >> report.txt
  elif cmp -s "src/$line" "orig/$line"; then
    echo "Файл $line без обновлений (имеет локальные изменения)" >> report.txt
  elif [ ! -e "orig/$line" ]; then
    echo "Прилетел новый файл $line, но у вас уже есть с таким же именем"
    [[ "$AUTOSYNC" == "1" ]] && echo "Требуется 'ручное' обновление" && exit 1
    see_and_merge "src/$line" "dst/$line" "orig/$line" || discard=1
  elif cmp -s "dst/$line" "orig/$line"; then
    echo "Файл $line автообновлен (небыло локальных изменений)"
    cp "src/$line" "dst/$line"
  else
    echo "Файл $line имеет локальные изменения."
    [[ "$AUTOSYNC" == "1" ]] && echo "Требуется 'ручное' обновление" && exit 1
    update_or_merge "src/$line" "dst/$line" "orig/$line" || discard=1
  fi
  if [ $discard -ne 0 ]; then break; fi
  cp "src/$line" "orig/$line"
done

cat report.txt

popd > /dev/null # "$wrk"

if [ $discard -eq 0 ]; then
  rsync -r "$wrkdst/" "$dst/"
  rsync -r "$wrkorig/" "$orig/"
  echo "Обновления успешно применены."
else
  echo "Прервано."
fi
rm -rf "$wrk"
