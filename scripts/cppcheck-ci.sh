#!/bin/bash
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
prj_dir="$PWD"

rm --force /tmp/cppcheck.cppcheck.log
set -o pipefail
$scriptdir/cppcheck.sh "$prj_dir" "$prj_dir/.cppcheck/suppressions.txt" "$prj_dir/.cppcheck/exclude_folders.txt"
res=$?
exit $res
