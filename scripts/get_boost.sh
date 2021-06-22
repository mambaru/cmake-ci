#!/bin/bash

ver=$1
ver_=${ver//./_}
for param in "${@:2}"
do
  boot_params="${boot_params}--with-libraries=$param "
  b2_params="${b2_params}--with-$param "
done

boost_name="boost_${ver_}"
boost_tar="${boost_name}.tar.gz"

boost_url="https://boostorg.jfrog.io/artifactory/main/release/$ver/source/${boost_tar}"
if [ ! -d "$boost_name" ]; then
  if [ ! -f "$boost_tar" ]; then
    echo "Download boost from ${boost_url} ..."
    curl -L ${boost_url} --output ${boost_tar}
  fi
  echo "Unpack ${boost_tar}..."
  tar -xf ${boost_tar}
fi

boost_root="${PWD}/boost"
pushd $boost_name
  echo "${boost_name} bootstrap..."
  ./bootstrap.sh --prefix=$boost_root boot_params > /dev/null
  echo "${boost_name} build shared..."
  ./b2 link=shared runtime-link=shared threading=multi ${b2_params} --prefix=$boost_root > /dev/null
  echo "${boost_name} install shared..."
  ./b2 ${b2_params} --prefix=$boost_root install > /dev/null
  echo "${boost_name} build static..."
  ./b2 link=static runtime-link=static threading=multi ${b2_params} --prefix=$boost_root > /dev/null
  echo "${boost_name} install static..."
  ./b2 ${b2_params} --prefix=$boost_root install > /dev/null
popd

echo echo "Delete ${PWD}/$boost_name..." > delete_boost.sh
echo rm -rf ${PWD}/$boost_name >> delete_boost.sh
echo rm -rf ${PWD}/$boost_tar >> delete_boost.sh
echo echo "${boost_name} Done!" >> delete_boost.sh

