#!/bin/bash

# Сборка, запуск тестов и формирования архива с бинарниками
# Предназначен для запуска при CI в gitlab
# можно и вручную, но необходимо експортировать все эти переменные:

  echo "CI_COMMIT_REF_NAME=$CI_COMMIT_REF_NAME"
  echo "BLDIR=${BLDIR}"
  echo "SCRIPTS=${SCRIPTS}"
  echo "BUILD_TESTING=${BUILD_TESTING}"
  echo "BUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}"
  echo "CXX_STANDARD=${CXX_STANDARD}"
  echo "CXX_COMPILER=${CXX_COMPILER}"
  echo "CODE_COVERAGE=${CODE_COVERAGE}"
  echo "BUILD_TYPE=${BUILD_TYPE}"
  echo "PARANOID_WARNINGS=${PARANOID_WARNING}"
  echo "MAKE_VERBOSE=${MAKE_VERBOSE}"
  echo "EXTRA_WARNINGS=${EXTRA_WARNINGS}"
  echo "CMAKE_ARGS=${CMAKE_ARGS}"

  echo "MAKE_ASSEMBLY=${MAKE_ASSEMBLY}"
  echo "DISTRIB_STANDARD=${DISTRIB_STANDARD}"
  echo "DISTRIB_COMPILER=${DISTRIB_COMPILER}"
  echo "DISTRIB_DRAFT=${DISTRIB_DRAFT}"
  echo "DISTRIB_BUGFIX=${DISTRIB_BUGFIX}"
  echo "DISTRIB_WIP=${DISTRIB_WIP}"
  echo "DISTRIB_DEVEL=${DISTRIB_DEVEL}"
  echo "DISTRIB_PRERELEASE=${DISTRIB_PRERELEASE}"
  echo "DISTRIB_RELEASE=${DISTRIB_RELEASE}"

  mkdir -p "${BLDIR}"

  pushd "${BLDIR}"
  pwd

    cmake .. ${CMAKE_ARGS} -DBUILD_TESTING=${BUILD_TESTING} -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS} \
                           -DCMAKE_CXX_STANDARD=${CXX_STANDARD} -DCMAKE_CXX_COMPILER=${CXX_COMPILER} \
                           -DCODE_COVERAGE=${CODE_COVERAGE} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
                           -DPARANOID_WARNINGS=${PARANOID_WARNING} -DCMAKE_VERBOSE_MAKEFILE=${MAKE_VERBOSE} \
                           -DEXTRA_WARNINGS=${EXTRA_WARNINGS} || exit 1

    cmake --build . -- -j${BUILD_THREADS} || exit 1
    ctest || exit 1
  popd

  if [[ "$CODE_COVERAGE" == "ON" ]] && [[ ${CXX_COMPILER:0:3} == g++ ]]; then
    ${SCRIPTS}/coverage-report.sh "${BLDIR}" "no-report" || exit 1
    lcov --summary ${BLDIR}/${CI_PROJECT_NAME}-coverage.info || exit 1
  fi

  if [[ ${MAKE_ASSEMBLY} == "ON" ]] && [[ ${DISTRIB_STANDARD} == ${CXX_STANDARD} ]] && [[ ${DISTRIB_COMPILER} == ${CXX_COMPILER} ]]; then

    if [[ $CI_COMMIT_REF_NAME == "draft" ]] && [[ ${DISTRIB_DRAFT} == ${BUILD_TYPE} ]]; then
      echo "Собираем сборку для демона. Версия DRAFT"
      ${SCRIPTS}/assembly.sh "${BLDIR}" "draft" || exit 1
    fi

    if [[ $CI_COMMIT_REF_NAME == "bugfix" ]] && [[ ${DISTRIB_BUGFIX} == ${BUILD_TYPE} ]]; then
      echo "Собираем сборку для демона. Версия bugfix"
      ${SCRIPTS}/assembly.sh "${BLDIR}" "bugfix" || exit 1
    fi

    if [[ $CI_COMMIT_REF_NAME == "wip-devel" ]] && [[ ${DISTRIB_WIP} == ${BUILD_TYPE} ]]; then
      echo "Собираем сборку для демона. Версия WIP" || exit 1
      ${SCRIPTS}/assembly.sh "${BLDIR}" "wip"
    fi

    if [[ $CI_COMMIT_REF_NAME == "devel" ]] && [[ ${DISTRIB_DEVEL} == ${BUILD_TYPE} ]]; then
      echo "Собираем сборку для демона. Версия devel"
      ${SCRIPTS}/assembly.sh "${BLDIR}" "devel" || exit 1
    fi

    if [[ $CI_COMMIT_REF_NAME == "pre-release" ]] && [[ ${DISTRIB_PRERELEASE} == ${BUILD_TYPE} ]]; then
      echo "Собираем сборку для демона. Версия pre-release"
      ${SCRIPTS}/assembly.sh "${BLDIR}" "pre-release" || exit 1
    fi

    if [[ $CI_COMMIT_REF_NAME == "master" ]] && [[ ${DISTRIB_RELEASE} == ${BUILD_TYPE} ]] ; then
      echo "Собираем сборку для демона. Версия release"
      ${SCRIPTS}/assembly.sh "${BLDIR}" "release" || exit 1
    fi
  fi
