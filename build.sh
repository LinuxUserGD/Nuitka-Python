#!/bin/bash


set -e
set -x

# Install Debian dependencies.
# TODO: Support Fedora/CentOS/etc. as well.

long_version=$(git branch --show-current 2>/dev/null || git symbolic-ref --short HEAD)
short_version=$(echo $long_version | sed -e 's#\.##')

# Have this as a standard path. We are not yet relocatable, but that will come hopefully.
target=/opt/nuitka-python${short_version}

# Allow to overload the compiler used via CC environment variable
if [ "$CC" = "" ]
then
  CC=clang
  CXX=clang++
else
  CXX=`echo "$CC" | sed -e 's#cc#++#'`
fi

# The UCS4 has best compatibility with wheels on PyPI it seems.
./configure --prefix=$target --disable-shared --enable-ipv6 --enable-unicode=ucs4 \
  --enable-optimizations --with-lto --without-gcc --without-icc --with-clang --with-computed-gotos --with-fpectl \
  CC=clang \
  CXX=clang++ \
  LIBS="-lffi -lbz2 -luuid -lsqlite3 -llzma"

make -j 4

# Delayed deletion of old installation, to avoid having it not there for testing purposes
# while compiling, which is slow due to PGO beign applied.
sudo rm -rf $target && sudo CC=clang CXX=clang++ make install

# Make sure to have pip installed, might even remove it afterwards, Debian
# e.g. doesn't include it.
sudo mv $target/lib/python${long_version}/pip.py $target/lib/python${long_version}/pip.py.bak && sudo $target/bin/python${long_version} -m ensurepip && sudo mv $target/lib/python${long_version}/pip.py.bak $target/lib/python${long_version}/pip.py
