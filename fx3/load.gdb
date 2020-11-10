set architecture arm
target remote localhost:3333
monitor halt
file ./domesdayDuplicator.elf
load
set $pc=CyU3PFirmwareEntry
b main
continue
