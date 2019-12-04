#!/bin/bash

message="cmake-ci update autocommit"
[ ! -z "$1" ] && message="$1"
echo "message=$message"

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

${scriptdir}/gitchef.sh || exit $?

function update_if ()
{
  git fetch origin master
  count1=$(git rev-list --count origin/master ^HEAD)
  count2=$(git rev-list --count HEAD ^origin/master )
  if (( $count2!=0 )); then
    echo "Опережение мастера на $count2"
  elif (( $count1!=0 )) ; then
    echo "Отставание от мастера на $count1. Обновляем."
    git checkout master
    git pull origin master
  else
    echo "Переключаем на master."
    git checkout master
  fi
}

#git submodule sync
#git submodule update --init

if [[ ! -d external/cmake-ci/cmake ]]; then
  git submodule update --init -- external/cmake-ci || exit $?
fi

export -f update_if
git submodule foreach update_if

#git submodule update --recursive

#if [ -d external/wfcroot ]; then
#  pushd external/wfcroot
#    git submodule sync
#    git submodule update --init
#  popd
#fi

[ ! -f ${prjdir}/.ci/scripts/after-update.sh ] || ${prjdir}/.ci/scripts/after-upgrade.sh || exit $?

git add .
if git commit -am "$message"; then
  echo "Все изменения автоматически зафиксированы. Для отмены наберите: "
  echo "  git reset --hard HEAD~1"
fi
echo "Дальнейшие инструкции найдете здесь:"
echo "  http://github.lan/cpp/cmake-ci/blob/master/Readme.md"
echo Done
exit 0