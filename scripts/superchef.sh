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
  git submodule update --init --depth=100
  git submodule foreach bash -c "check_subsubmodule $1 ${PWD##*/}"
  ret=$?
  git submodule deinit --force .
  return $ret
}

export -f check_submodule
export -f check_subsubmodule
git submodule update --init --depth=100
git submodule foreach bash -c "check_submodule ${PWD##*/}"
