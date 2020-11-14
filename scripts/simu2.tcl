
#
# Copyright (C) Telecom ParisTech
# Copyright (C) Renaud Pacalet (renaud.pacalet@telecom-paristech.fr)
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

proc usage {} {
	puts "usage: vivado -mode batch -source <script> -tclargs <rootdir> <builddir> \[<board>\] \[<ila>\]"
	puts "  <rootdir>:  absolute path of dmon root directory"
	puts "  <builddir>: absolute path of build directory"
	puts "  <board>:    target board (zybo, zed or zc706, default zybo)"
	puts "  <ila>:      embed Integrated Logic Analyzer (0 or 1, default 0)"
	exit -1
}

if { $argc == 2} {
	set rootdir [lindex $argv 0]
	set builddir [lindex $argv 1]
	set board [lindex $argv 2]
	set part "xc7z020clg484-1"
	set board "em.avnet.com:zed:part0:1.3"
	set range 512M
	
  puts "*********************************************"
	puts "Summary of build parameters"
	puts "*********************************************"
	puts "Board: $board"
	puts "Part: $part"
	puts "Root directory: $rootdir"
	puts "Build directory: $builddir"
	puts -nonewline "Integrated Logic Analyzer: "
	puts "*********************************************"
} else {
	usage
}

cd $builddir

###################
# Create GPIF IP #
###################
create_project -part $part -force gpif gpif
set sources {gpif oddr2}
foreach f $sources {
        add_files $rootdir/hdl/$f.vhd
}
import_files -force -norecurse
ipx::package_project -root_dir gpif -vendor www.eurecom.fr -library GPIF -force gpif
close_project

###################
# Create DMON IP #
###################
create_project -part $part -force producer producer
set sources {producer}
foreach f $sources {
        add_files $rootdir/hdl/$f.vhd
}
import_files -force -norecurse
ipx::package_project -root_dir producer -vendor www.eurecom.fr -library PRODUCER -force producer
close_project


############################
## Create top level design #
############################
set top top
create_project -part $part -force $top .
set_property board_part $board [current_project]
set_property ip_repo_paths { ./gpif ./producer } [current_fileset]
update_ip_catalog
create_bd_design "$top"
set gpif [create_bd_cell -type ip -vlnv [get_ipdefs *www.eurecom.fr:GPIF:gpif:*] gpif]
set producer [create_bd_cell -type ip -vlnv [get_ipdefs *www.eurecom.fr:PRODUCER:producer:*] producer]

create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_0
  set_property -dict [list \
CONFIG.Input_Data_Width {64} \
CONFIG.Input_Depth {8192} \
CONFIG.Output_Data_Width {32} \
CONFIG.Output_Depth {16384} \
CONFIG.Reset_Pin {false} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Use_Dout_Reset {false} \
CONFIG.Write_Acknowledge_Flag {false} \
CONFIG.Programmable_Empty_Type {Single_Programmable_Empty_Threshold_Constant} \
CONFIG.Empty_Threshold_Assert_Value {4096} \
CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
CONFIG.Full_Threshold_Assert_Value {8184} \
CONFIG.Overflow_Flag {true} \
] [get_bd_cells fifo_generator_0]

connect_bd_net [get_bd_pins gpif/fifo_prog_empty] [get_bd_pins fifo_generator_0/prog_empty]
connect_bd_net [get_bd_pins fifo_generator_0/dout] [get_bd_pins gpif/fifo_out]
connect_bd_net [get_bd_pins fifo_generator_0/rd_en] [get_bd_pins gpif/fifo_read]
connect_bd_net [get_bd_pins fifo_generator_0/prog_full] [get_bd_pins producer/fifo_almost_full]
connect_bd_net [get_bd_pins fifo_generator_0/din] [get_bd_pins producer/fifo_in]
connect_bd_net [get_bd_pins fifo_generator_0/wr_en] [get_bd_pins producer/fifo_write]

make_bd_pins_external  [get_bd_pins producer/aclk]
set_property name aclk [get_bd_ports aclk_0]
make_bd_pins_external  [get_bd_pins producer/aresetn]
set_property name aresetn [get_bd_ports aresetn_0]
connect_bd_net [get_bd_ports aclk] [get_bd_pins fifo_generator_0/clk]
connect_bd_net [get_bd_ports aclk] [get_bd_pins gpif/aclk]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins gpif/aresetn]
make_bd_pins_external  [get_bd_pins fifo_generator_0/overflow]
set_property name overflow [get_bd_ports overflow_0]

make_bd_pins_external  [get_bd_pins gpif/fx3_resetn]
set_property name fx3_resetn [get_bd_ports fx3_resetn_0]
make_bd_pins_external  [get_bd_pins gpif/fx3_read_ready]
set_property name fx3_read_ready [get_bd_ports fx3_read_ready_0]
make_bd_pins_external  [get_bd_pins gpif/clk_out]
set_property name clk_out [get_bd_ports clk_out_0]
make_bd_pins_external  [get_bd_pins gpif/fx3_data_available]
set_property name fx3_data_available [get_bd_ports fx3_data_available_0]
make_bd_pins_external  [get_bd_pins gpif/data]
set_property name data [get_bd_ports data_0]

validate_bd_design
set files [get_files *$top.bd]
generate_target all $files
add_files -norecurse -force [make_wrapper -files $files -top]
save_bd_design

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse $rootdir/tb/tb_fx3.sv
update_compile_order -fileset sim_1

generate_target Simulation [get_files $builddir/top.srcs/sources_1/bd/top/top.bd]
export_ip_user_files -of_objects [get_files $builddir/top.srcs/sources_1/bd/top/top.bd] -no_script -sync -force -quiet
export_simulation -of_objects [get_files $builddir/top.srcs/sources_1/bd/top/top.bd] -directory $builddir/top.ip_user_files/sim_scripts -ip_user_files_dir $builddir/top.ip_user_files -ipstatic_source_dir $builddir/top.ip_user_files/ipstatic -lib_map_path [list {modelsim=$builddir/top.cache/compile_simlib/modelsim} {questa=$builddir/top.cache/compile_simlib/questa} {ies=$builddir/top.cache/compile_simlib/ies} {xcelium=$builddir/top.cache/compile_simlib/xcelium} {vcs=$builddir/top.cache/compile_simlib/vcs} {riviera=$builddir/top.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

launch_simulation

#open_vcd trace.vcd

#log_vcd TCK
#log_vcd TMS
#log_vcd TDI
#log_vcd TDO

#restart
#run 10 us
#run 10 us
#run 10 us
#flush_vcd
#close_vcd
#close_sim
#exit
