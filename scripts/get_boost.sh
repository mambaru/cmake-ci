#!/bin/bash

ver="${1:-1.80.0}"
ver_=${ver//./_}
for param in "${@:2}"
do
  boot_params="${boot_params}--with-libraries=$param "
  b2_params="${b2_params}--with-$param "
done

boost_name="boost_${ver_}"
boost_tar="${boost_name}.tar.gz"
boost_url="https://boostorg.jfrog.io/artifactory/main/release/$ver/source/${boost_tar}"

if [ ! -f "$boost_tar" ]; then
  echo "Download boost from ${boost_url} ..."
  wget ${boost_url} -O ${boost_tar} || exit 1
fi
echo "Unpack ${boost_tar}..."
if ! tar -xf ${boost_tar}; then
  echo "Download boost from ${boost_url} ..."
  #curl -L ${boost_url} --output ${boost_tar}
  wget ${boost_url} -O ${boost_tar} || exit 1
  tar -xf ${boost_tar} || exit 1
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


