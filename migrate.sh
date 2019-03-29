#!/bin/bash

if [ -z "$1" ]; then
  repo="git@github.lan:cpp/cmake-ci.git"
  #для github.com
  #echo "Usage: "
  #echo -e "\t$0 path-to-cmake-ci-repo"
  #echo "Example:"
  #echo -e "\t$0 https://github.com/mambaru/cmake-ci.git"
  #exit 1
else
  repo="$1"
fi

git submodule deinit -f .
rm -rf .git/modules
git rm -rf external
git rm -rf .gitmodules
git submodule add --force $repo external/cmake-ci
git commit -m "Prepare migrate to github autocommit"
