#!/bin/bash

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
prjdir="${PWD}"

echo "rm -rf ${prjdir}/build/boost_*"
rm -rf ${prjdir}/build/boost_*
