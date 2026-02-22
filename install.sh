#!/bin/bash

set -e

rm -rf build
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=`qmake6 -query QT_INSTALL_PREFIX` -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib ../
make
sudo make install
kquitapp6 plasmashell
kstart plasmashell
