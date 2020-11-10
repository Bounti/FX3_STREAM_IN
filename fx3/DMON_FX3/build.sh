#!/usr/bin/env bash

make clean

make FX3_INSTALL_PATH=../cyfx3sdk/ FX3FWROOT=../cyfx3sdk/ ARMGCC_INSTALL_PATH=../arm-2013.11/ all

../cyfx3sdk/util/elf2img/elf2img -vectorload yes -i *.elf -o *.img

cd ../cyusb_linux_1.0.5/

./src/download_fx3 -t I2C -i ../DMON_FX3/domesdayDuplicator.img
