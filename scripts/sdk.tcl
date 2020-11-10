proc usage {} {
	puts "usage: xsct -interactive ./scripts/sdk.tcl <application>"
	puts "  <application>: supported applications are Hello World;Dhrystone;Memory Tests;Zynq DRAM tests"
}

if { $argc == 1 } {
	set app [lindex $argv 0]
} else {
 usage
 exit -1
}

puts $app

variable cdir [file dirname [file normalize [info script]]]

setws ./build/top.sdk/

createhw -name hw1 -hwspec ./build/top.sdk/top_wrapper.hdf

cd ./build/top.sdk

createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone

setlib -bsp bsp1 -lib xilffs
updatemss -mss bsp1/system.mss
regenbsp -bsp bsp1

createapp -name app -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -lang C -app $app

createapp -name fsbl -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -lang C -app {Zynq FSBL}

#exec rm -rf $cdir/../build/top.sdk/app/src/helloworld.c
#exec rm -rf $cdir/../build/top.sdk/app/src/lscript.ld
#exec ln -s $cdir/../C/bare_metal.c $cdir/../build/top.sdk/app/src/helloworld.c
#exec ln -s $cdir/../C/callee.s $cdir/../build/top.sdk/app/src/callee.s
#exec ln -s $cdir/../C/lscript.ld $cdir/../build/top.sdk/app/src/lscript.ld

sdk projects -build

exec bootgen -arch zynq -image ../../scripts/app.bif -w -o BOOT.bin

exec program_flash -f ./BOOT.bin -fsbl ./fsbl/Debug/fsbl.elf -flash_type qspi-x1-single -blank_check -verify -cable type xilinx_tcf url TCP:localhost:3121

