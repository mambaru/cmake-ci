#!/bin/bash
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
prj_dir="$PWD"

rm --force /tmp/cppcheck.cppcheck.log
$scriptdir/cppcheck.sh "$prj_dir" "$prj_dir/.cppcheck/suppressions.txt" "$prj_dir/.cppcheck/exclude_folders.txt" $@ |& tee /tmp/cppcheck.cppcheck.log
res=$?
sh -c "! grep '\[' /tmp/cppcheck.cppcheck.log" > /dev/null
rm --force /tmp/cppcheck.cppcheck.log
exit $res
