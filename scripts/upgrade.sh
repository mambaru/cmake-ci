#!/bin/bash

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
prjdir="${PWD}"

# возможное значение "auto"
[[ -n "$1" ]] && [[ "$1" == "auto" ]] && export AUTOSYNC=1
[ ! -z "$2" ] && branch="$2"

message="cmake-ci upgrade autocommit"
[ ! -z "$3" ] && message="$3"
echo "message=$message"

if [[ ! -d external/cmake-ci/cmake ]]; then
  git submodule update --init -- external/cmake-ci || exit $?
fi

if [[ ! -d external/cmake-ci/cmake ]]; then
  echo "ERROR: git submodule external/cmake-ci required!"
  exit 1
fi

if [[ ! -z "$branch" ]]; then
  pushd external/cmake-ci
  git checkout $branch || exit $?
  git pull origin $branch
  popd
fi

# проверка возможности апгрейда (все субмодули синхронизированы )
#TODO: это только для авторежима в ночных сборках
#перенести в yaml
#${scriptdir}/gitchef.sh submodules || exit $?
${scriptdir}/gitchef.sh || exit $?


# #################################################################################
# #################################################################################
# #################################################################################

if [[ "$AUTOSYNC" != "1" ]]; then
  echo "你好亲爱的朋友！"
  echo "Этот скрипт подготовит (обновит) твой проект для непрерывной сборки в gitlab-ci."
  echo "Убедитесь, что вы запускаете его из корневой директории проекта. Если проект уже "
  echo "подготовлен, то он будет обновлен до последней версии из master (бранч можно указать "
  echo "первым аргументом). По завершению работы скрипта будет добавлен git submodule external/cmake-ci "
  echo "и интерастовно обновлены некоторые файлы. Продолжаем?"

  select yn in "Yes" "No"
  do
    case $yn in
        Yes ) break;;
        No ) exit;;
        * ) echo "Вот ты лопух! Зачем всякую дичь печатаешь? Надо число '1' или '2', что не понятно? Уверен что в состоянии дальше продолжать?"
    esac
  done
fi

# слияние папок
${scriptdir}/irsync.sh external/cmake-ci/root-ci . .ci || exit $?
[ ! -f ${prjdir}/.ci/scripts/after-upgrade.sh ] || ${prjdir}/.ci/scripts/after-upgrade.sh || exit $?

git add .
if git commit -am "$message"; then
  echo "Все изменения автоматически зафиксированы. Для отмены, наберите: "
  echo "  git reset --hard HEAD~1"
fi
echo "Дальнейшие инструкции найдете здесь:"
echo "  http://github.lan/cpp/cmake-ci/blob/master/Readme.md"
echo Done
