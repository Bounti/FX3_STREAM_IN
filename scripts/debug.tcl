connect -url tcp:127.0.0.1:3121
# Source the ps7_init.tcl script and run ps7_init and ps7_post_config commands
source ./hw1/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zed 210248A398A9"} -index 0
loadhw -hw ./hw1/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zed 210248A398A9"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248A398A9"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248A398A9"} -index 0
# Download the application program
dow ./app/Debug/app.elf
configparams force-mem-access 0

# Set a breakpoint at main()
bpadd -addr &main
# Resume the processor core
con
# Registers can be viewed when the core is stopped
rrd
# Local variables can be viewed
locals
# Step over a line of source code
#nxt
# View stack trace
# bt
bpadd -file helloworld.c -line 172 -type hw
con
