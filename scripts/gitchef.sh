#!/bin/bash

# Определяеть допустимость манипуляций с git-проектом

if [ -f ".git" ]; then
  echo "Ошибка! Не нужно запускать это в git-субмодуле. Склонируйте этот проект в отдельную директорию."
  exit 1
fi

if [ ! -d ".git" ]; then
  echo "Ошибка! Этот скрипт нужно запускать только в корневой git-папке проекта."
  exit 1
fi

if ! git diff-index --quiet HEAD -- ; then
  echo "Ошибка! У вас есть не зафиксированные изменения! Сделайте git commit и повторно запустите этот скрипт"
  exit 1
fi

function exit_subm() {
  echo "Нужно переключить субмодуль ${PWD##*/} на конкретную ветку или выполнить update"
  exit $?
}

function check() {

  UPSTREAM='@{u}'
  LOCAL=$(git rev-parse @)  || exit_subm $?
  REMOTE=$(git rev-parse "$UPSTREAM")  || exit_subm $?
  BASE=$(git merge-base @ "$UPSTREAM")  || exit_subm $?

  if [ $LOCAL = $REMOTE ]; then
      echo "Up-to-date"
  elif [ $LOCAL = $BASE ]; then
      echo "Ошибка! Удаленная ветка опережает локальную. Сделайте git pull чтобы не огрести проблем!"
      exit 1
  elif [ $REMOTE = $BASE ]; then
      echo "Need to push"
  else
      echo "Diverged! Ветки разошлись!"
      exit 1
  fi
  echo "Done ${PWD}"
}


check
if [[ "$1" == "submodules" ]]; then
  export -f check
  export -f exit_subm
  git submodule foreach check
fi
