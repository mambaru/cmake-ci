#!/bin/bash

# Run from project root ./external/cmake-ci/scripts/coverage-report.sh
# Options:
# $1 [./build] build directory
# $2 [./build/cov-report] report directory or no-report if not needed (for ci)

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
project_name="$(basename ${PWD})"
prjdir="${PWD}"

if [ -z "$1" ]; then
  build_dir="${prjdir}/build"
else
  build_dir="${prjdir}/$1"
fi

if [ -z "$2" ]; then
  cov_report=$build_dir/cov-report
else
  cov_report="$2"
fi

echo $build_dir
if [ ! -d "$build_dir" ]; then
  echo "You need to build ($build_dir) a project with the option -DCODE_COVERAGE=ON and run tests"
  exit 1
fi

# Проверяем, что созданы необходимые файлы
gcda_count="$(find ./ -type f -iname '*.gcda' | wc -l)"

if [ "$gcda_count" = "0" ]; then
  echo "Not found * .gcda files"
  echo "You need to build a project with the option -DCODE_COVERAGE=ON and run tests"
  exit 1
fi

cov_info=$build_dir/$project_name-coverage.info

rm -f $cov_info

echo "We collect data for the report..."
lcov --quiet --capture --directory "$build_dir" --base-directory $prjdir --no-external --output-file $cov_info \
  || lcov --ignore-errors mismatch,mismatch --quiet --capture --directory "$build_dir" --base-directory $prjdir --no-external --output-file $cov_info  \
  || exit 1
echo "Delete data for submodules..."
lcov --quiet --remove $cov_info '*/external/*' --output-file $cov_info || exit 2

if [ "$cov_report" != "no-report" ]; then
  lcov --summary $cov_info
  if [ "$cov_report" != "summary" ]; then
    rm -rf $cov_report
    echo "Create html report..."
    mkdir $cov_report
    genhtml --quiet -o $cov_report $cov_info || exit 3
    echo "To view the report run:"
    echo -e "\tgoogle-chrome $cov_report/index.html"
  fi
fi
