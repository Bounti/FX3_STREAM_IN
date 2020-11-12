set architecture arm
target remote localhost:3333
monitor halt
file ./build/src/fx3_dmon.elf
load
set $pc=CyU3PFirmwareEntry
b main
continue
