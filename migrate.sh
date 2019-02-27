#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 path-to-cmake-ci-repo"
  echo "Example: $0 git@github.lan:cpp/cmake-ci.git"
  exit 1
fi

git submodule deinit -f .
rm -rf .git/modules
git rm -rf .gitmodules
git rm -rf external
git submodule add --force $1 external/cmake-ci
