#!/bin/bash

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
prjdir="${PWD}"

[ ! -f ${scriptdir}/gitchef.sh ] || ${scriptdir}/gitchef.sh || exit $?

if [ -z "$1" ]; then
  echo "Нужно указать путь к cmake-ci, например: "
  echo "  $0 ../cmake-ci.git"
  echo "  $0 ../../mambaru/cmake-ci.git"
  echo "  $0 https://github.com/mambaru/cmake-ci.git"
  exit 1
fi

repo="$1"
auto="$2"

echo "Этот скрипт удаляет все субмодули из текущего проекта и переподключает субмодуль cmake-ci."

if [[ "${auto}" != "auto" ]]; then
  while true; do
      read -p "Вы уверены что хотите это сделать? " yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
fi

count=$(git submodule | wc -l)
if (( $count > 0 )); then
  git submodule deinit -f . > /dev/null 2>&1
  rm -rf .git/modules > /dev/null 2>&1
  rm -rf external > /dev/null 2>&1
  rm -rf .gitmodules > /dev/null 2>&1
  git add external > /dev/null 2>&1
  git add .gitmodules > /dev/null 2>&1
  git commit -m "[CI] reset-ci delete all submodules" || exit $?
fi

git submodule add ${repo} external/cmake-ci || exit $?

if [[ $scriptdir == $prjdir ]]; then
  echo "Самоуничтожение"
  rm -- "$prjdir/reset-ci.sh"
fi

echo "Done!"
