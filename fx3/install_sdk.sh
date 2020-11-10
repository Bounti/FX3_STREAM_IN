#!/usr/bin/env bash

SCRIPT_ROOT=$(pwd)
cd ./arm-2013.11/lib/gcc/arm-none-eabi/
rsync -a ./4.8.1/* ./

cd $SCRIPT_ROOT
gcc ./cyfx3sdk/util/elf2img/elf2img.c -o ./cyfx3sdk/util/elf2img/elf2img

cd $SCRIPT_ROOT
cd ./cyusb_linux_1.0.5/
sudo -S add-apt-repository ppa:rock-core/qt4
sudo -S apt install qt4-default qt4-dev-tools qt4-qmake
find -name "main.cpp" -type f -print0 | xargs -0 sed -i 's/errno/_errno/g'
sudo -S ./install.sh
sudo ldconfig $(pwd)/lib/libcyusb.so
sudo udevadm control --reload-rules && sudo udevadm trigger

cd $SCRIPT_ROOT
cd cyusb_linux_1.0.5/src
make
