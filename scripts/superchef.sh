#!/bin/bash
# Только для ночных сборок!
# Определяет допустимость автоматического обновления до master
# всех субмодулей верхнего уровня. Проверяет для каждого субмодуля
# наличиче вложенных субмодулей чтобы текущая ветка не отставала
# от master. Нет смысла автоматически обновлять субмодуль если вложенный
# субмодуль также требует обновления. Если этого не делать, то проект будет
# обновляться и пушиться пересобираться каждую ночь, пока все субсубмодули
# не догонят мастер в процессе ночных обновлений

function check_subsubmodule {
  echo ">> >> check_subsubmodule $1 ($PWD)"
  git fetch origin master
  master=$(git rev-list --count origin/master)
  head=$(git rev-list --count HEAD)
  count=$(( master - head ))
  ret=$(( count > 0 ))
  if [ "$ret" -ne "0" ]; then
    echo ""
    echo "################################################################################"
    echo "# Не прошел: СубCубмодуль $1/$2/${PWD##*/} отстает от мастера на $count коммитов"
    echo "################################################################################"
  fi
  return $ret
}

function check_submodule {
  echo ">> check_submodule $1 ($PWD)"
  git checkout master
  git pull origin master
  git submodule update --init
  git submodule foreach "$(declare -f check_subsubmodule); check_subsubmodule $1 ${PWD##*/}"
  ret=$?
  git submodule deinit --force .
  return $ret
}

export -f check_submodule
export -f check_subsubmodule
git submodule update --init --depth=100
git submodule foreach "$(declare -f check_subsubmodule); check_submodule ${PWD##*/}"
git submodule update --recursive
