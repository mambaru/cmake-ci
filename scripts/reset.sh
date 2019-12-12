#!/bin/bash

if [ -z "$1" ]; then
  echo "Нужно указать путь к cmake-ci, например: "
  echo "  git@github.lan:cpp/cmake-ci.git"
  echo "  git@github.lan:testci/cmake-ci.git"
  echo "  https://github.com/mambaru/cmake-ci.git"
  exit 1
fi

repo="$1"
auto="$2"

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
prjdir="${PWD}"

#${scriptdir}/gitchef.sh || exit $?

echo "Этот скрипт удаляет все субмодули и cmake-ci файлы из текущего проекта, переподключает субмодуль cmake-ci"
echo "и производит upgrade проекта для последней версии cmake-ci из $repo"
echo "Используется для:"
echo "  1. Для миграции проекта в другой репозитарий (указывается первым параметром)"
echo "  2. Предварительной подготовки старых не интегрированных в CI проектов"
echo "  3. Для обновления интегрированных в CI, но сильно устаревших проектов, для которых make upgrade не работает,"
echo "    работает некорректно или остается много мусора от предыдущей версии"

function auto_rm ()
{
  if [[ $scriptdir == $prjdir ]]; then
    echo "самоуничтожение"
    rm -- "$prjdir/reset.sh"
  fi
}

if [[ "${auto}" != "auto" ]]; then
  while true; do
      read -p "Вы уверены что хотите это сделать? " yn
      case $yn in
          [Yy]* ) make install; break;;
          [Nn]* ) auto_rm; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
fi

git submodule deinit -f . || exit $?
rm -rf .git/modules
git rm -rf external
git rm -rf .gitmodules
git submodule add --force $repo external/cmake-ci || exit $?

[ ! -f ${prjdir}/.ci/scripts/after-reset.sh ] || ${prjdir}/.ci/scripts/after-reset.sh || exit $?

auto_rm
git add .
if git commit -m "cmake-ci reset autocommit"; then
  echo "Все изменения автоматически зафиксированы. Для отмены, наберите: "
  echo "  git reset --hard HEAD~1"
fi

