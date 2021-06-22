#!/bin/bash

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
prjdir="${PWD}"

if [ -f ${prjdir}/build/delete_boost.sh ]; then
  bash ${prjdir}/build/delete_boost.sh
  rm ${prjdir}/build/delete_boost.sh
fi
