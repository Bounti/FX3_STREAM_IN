#
# Copyright (C) Telecom ParisTech
# Copyright (C) Renaud Pacalet (renaud.pacalet@telecom-paristech.fr)
# Copyright (C) Nassim Corteggiani (n.corteggiani@gmail.com)
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

#                        "led[7]"        { "U14"  "LVCMOS33" }
#                        "led[6]"        { "U19"  "LVCMOS33" }
#                        "led[5]"        { "W22"  "LVCMOS33" }
#                        "led[4]"        { "V22"  "LVCMOS33" }
#      "overflow_0"        { "U14"  "LVCMOS33" }


if { $argc == 4 } {
	set rootdir [lindex $argv 0]
	set builddir [lindex $argv 1]
	set board [lindex $argv 2]
	if { [ string equal $board "zybo" ] } {
		set part "xc7z010clg400-1"
		set board "digilentinc.com:zybo:part0:1.0"
		set range 512M
		array set ios {
			"sw[0]"         { "G15" "LVCMOS33" }
			"sw[1]"         { "P15" "LVCMOS33" }
			"sw[2]"         { "W13" "LVCMOS33" }
			"sw[3]"         { "T16" "LVCMOS33" }
			"led[0]"        { "M14" "LVCMOS33" }
			"led[1]"        { "M15" "LVCMOS33" }
			"led[2]"        { "G14" "LVCMOS33" }
			"led[3]"        { "D18" "LVCMOS33" }
			"btn"           { "R18" "LVCMOS33" }
		}
	} elseif { [ string equal $board "zed" ] } {
		set part "xc7z020clg484-1"
		set board "em.avnet.com:zed:part0:1.3"
		set range 512M
		array set ios {
      "led[0]"        { "T22"  "LVCMOS33" }
      "led[1]"        { "T21"  "LVCMOS33" }
      "led[2]"        { "U22"  "LVCMOS33" }
      "led[3]"        { "U21"  "LVCMOS33" }
      "led[4]"        { "V22"  "LVCMOS33" }
      "led[5]"        { "W22"  "LVCMOS33" }
      "led[6]"        { "U19"  "LVCMOS33" }
      "led[7]"        { "U14"  "LVCMOS33" }
      "clk_out"       { "M19"  "LVCMOS25" }
      "fx3_resetn"        { "B17" "LVCMOS25" } 
      "fx3_read_ready"    { "G20" "LVCMOS25" } 
      "fx3_data_available" { "K21" "LVCMOS25" } 
      "slcs"          { "K21" "LVCMOS25" } 
      "slwr"          { "G20" "LVCMOS25" } 
      "sloe"          { "G22" "LVCMOS25" } 
      "flaga"         { "F19" "LVCMOS25" } 
      "flagb"         { "D22" "LVCMOS25" } 
      "addr[0]"       { "B21"  "LVCMOS25" }
      "addr[1]"       { "B22"  "LVCMOS25" }
      "data[24]"      { "L18"  "LVCMOS25" }
      "data[25]"      { "P17"  "LVCMOS25" }
      "data[26]"      { "P18"  "LVCMOS25" }
      "data[27]"      { "M21"  "LVCMOS25" }
      "data[28]"      { "M22"  "LVCMOS25" }
      "data[29]"      { "T16"  "LVCMOS25" }
      "data[30]"      { "T17"  "LVCMOS25" }
      "data[31]"      { "N17"  "LVCMOS25" }
      "data[16]"      { "N18"  "LVCMOS25" }
      "data[17]"      { "J16"  "LVCMOS25" }
      "data[18]"      { "J17"  "LVCMOS25" }
      "data[19]"      { "G15"  "LVCMOS25" }
      "data[20]"      { "G16"  "LVCMOS25" }
      "data[21]"      { "E19"  "LVCMOS25" }
      "data[22]"      { "E20"  "LVCMOS25" }
      "data[23]"      { "A18"  "LVCMOS25" }
      "data[8]"       { "A19"  "LVCMOS25" }
      "data[9]"       { "A16"  "LVCMOS25" }
      "data[10]"      { "A17"  "LVCMOS25" }
      "data[11]"      { "C15"  "LVCMOS25" }
      "data[12]"      { "B15"  "LVCMOS25" }
      "data[13]"      { "A21"  "LVCMOS25" }
      "data[14]"      { "A22"  "LVCMOS25" }
      "data[15]"      { "D18"  "LVCMOS25" }
      "data[0]"       { "C19"  "LVCMOS25" }
      "data[1]"       { "N22"  "LVCMOS25" }
      "data[2]"       { "P22"  "LVCMOS25" }
      "data[3]"       { "J21"  "LVCMOS25" }
      "data[4]"       { "J22"  "LVCMOS25" }
      "data[5]"       { "P20"  "LVCMOS25" }
      "data[6]"       { "P21"  "LVCMOS25" }
      "data[7]"       { "J20"  "LVCMOS25" }
    }
	} elseif { [ string equal $board "zc706" ] } { 
		set part "xc7z045ffg900-2"
		set board "xilinx.com:zc706:part0:1.3"
		set range 1G
		array set ios {
			"sw[0]"         { "AB17" "LVCMOS25" }
			"sw[1]"         { "AC16" "LVCMOS25" }
			"sw[2]"         { "AC17" "LVCMOS25" }
			"sw[3]"         { "AJ13" "LVCMOS25" }
			"led[0]"        { "Y21"  "LVCMOS25" }
			"led[1]"        { "G2"   "LVCMOS15" }
			"led[2]"        { "W21"  "LVCMOS25" }
			"led[3]"        { "A17"  "LVCMOS15" }
			"btn"           { "R27"  "LVCMOS25" }
		}
	} else {
		usage
	}
	set ila [lindex $argv 3]
	if { $ila != 0 && $ila != 1 } {
		usage
	}
	puts "*********************************************"
	puts "Summary of build parameters"
	puts "*********************************************"
	puts "Board: $board"
	puts "Part: $part"
	puts "Root directory: $rootdir"
	puts "Build directory: $builddir"
	puts -nonewline "Integrated Logic Analyzer: "
	if { $ila == 0 } {
		puts "no"
	} else {
		puts "yes"
	}
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
#CONFIG.Input_Depth {8192} \
#CONFIG.Almost_Full_Flag {true} \

connect_bd_net [get_bd_pins gpif/fifo_prog_empty] [get_bd_pins fifo_generator_0/prog_empty]
connect_bd_net [get_bd_pins fifo_generator_0/dout] [get_bd_pins gpif/fifo_out]
connect_bd_net [get_bd_pins fifo_generator_0/rd_en] [get_bd_pins gpif/fifo_read]
connect_bd_net [get_bd_pins fifo_generator_0/prog_full] [get_bd_pins producer/fifo_almost_full]
connect_bd_net [get_bd_pins fifo_generator_0/din] [get_bd_pins producer/fifo_in]
connect_bd_net [get_bd_pins fifo_generator_0/wr_en] [get_bd_pins producer/fifo_write]
connect_bd_net [get_bd_pins fifo_generator_0/overflow] [get_bd_pins gpif/overflow]

set ps7 [create_bd_cell -type ip -vlnv [get_ipdefs *xilinx.com:ip:processing_system7:*] ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } $ps7
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {95.000000} CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL}] [get_bd_cells ps7]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/ps7/FCLK_CLK0 (100 MHz)" }  [get_bd_pins producer/aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/ps7/FCLK_CLK0 (100 MHz)" }  [get_bd_pins fifo_generator_0/clk]
#set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000}] $ps7
#set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1}] $ps7
#set_property -dict [list CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {1}] $ps7

# Addresses ranges
#set_property offset 0x40000000 [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]
#set_property range 1G [get_bd_addr_segs -of_object [get_bd_intf_pins /ps7/M_AXI_GP0]]


# Enable interrupt
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/ps7/FCLK_CLK0 (100 MHz)" }  [get_bd_pins gpif/aclk]

connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins ps7/M_AXI_GP0_ACLK]
#connect_bd_net [get_bd_pins gpif/aresetn] [get_bd_pins ps7/FCLK_RESET0_N]

create_bd_port -dir O clk_out
connect_bd_net [get_bd_pins /gpif/clk_out] [get_bd_ports clk_out]

#create_bd_port -dir I flaga
#connect_bd_net [get_bd_pins /gpif/flaga] [get_bd_ports flaga]

#create_bd_port -dir I flagb
#connect_bd_net [get_bd_pins /gpif/flagb] [get_bd_ports flagb]

create_bd_port -dir I fx3_resetn
connect_bd_net [get_bd_pins /gpif/fx3_resetn] [get_bd_ports fx3_resetn]

create_bd_port -dir I fx3_read_ready 
connect_bd_net [get_bd_pins /gpif/fx3_read_ready] [get_bd_ports fx3_read_ready]

create_bd_port -dir O fx3_data_available
connect_bd_net [get_bd_pins /gpif/fx3_data_available] [get_bd_ports fx3_data_available]

#create_bd_port -dir O sloe
#connect_bd_net [get_bd_pins /gpif/sloe] [get_bd_ports sloe]

#create_bd_port -dir O slcs
#connect_bd_net [get_bd_pins /gpif/slcs] [get_bd_ports slcs]

#create_bd_port -dir O slwr
#connect_bd_net [get_bd_pins /gpif/slwr] [get_bd_ports slwr]

#create_bd_port -dir O addr
#connect_bd_net [get_bd_pins /gpif/addr] [get_bd_ports addr]

create_bd_port -dir IO -from 31 -to 0 data
connect_bd_net [get_bd_pins /gpif/data] [get_bd_ports data]

create_bd_port -dir O -from 7 -to 0 led
connect_bd_net [get_bd_pins /gpif/led] [get_bd_ports led]

# Synthesis flow
validate_bd_design
set files [get_files *$top.bd]
generate_target all $files
add_files -norecurse -force [make_wrapper -files $files -top]
save_bd_design
set run [get_runs synth*]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none $run
launch_runs $run
wait_on_run $run
open_run $run

# IOs
foreach io [ array names ios ] {
  set port [get_port $io]
  if { [llength $port] != 0 } {
	  set pin [ lindex $ios($io) 0 ]
	  set std [ lindex $ios($io) 1 ]
	  set_property package_pin $pin [get_ports $io]
	  set_property iostandard $std [get_ports [list $io]]
  }
}

# Timing constraints
set clock [get_clocks]
set_false_path -from $clock -to [get_ports {led[*]}]
#set_false_path -from $clock -to [get_ports {status}]
#set_false_path -from $clock -to [get_ports {overflow}]
#set_false_path -from [get_ports {sw}] -to $clock

create_generated_clock -source [get_pins -hierarchical gpif/aclk] -master_clock [get_clocks] -add -name clk_out [get_ports clk_out] -edges {2 3 4}

set clock [get_clocks clk_fpga_0]
set_input_delay -clock $clock 1 [get_ports data]
set_input_delay -clock $clock 1 [get_ports fx3_read_ready]
set_input_delay -clock $clock 1 [get_ports fx3_resetn]

# Implementation
save_constraints
set run [get_runs impl*]
reset_run $run
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true $run
launch_runs -to_step write_bitstream $run
wait_on_run $run

# Messages
set rundir ${builddir}/$top.runs/$run
puts ""
puts "*********************************************"
puts "\[VIVADO\]: done"
puts "*********************************************"
puts "Summary of build parameters"
puts "*********************************************"
puts "Board: $board"
puts "Part: $part"
puts "Root directory: $rootdir"
puts "Build directory: $builddir"
puts -nonewline "Integrated Logic Analyzer: "
if { $ila == 0 } {
	puts "no"
} else {
	puts "yes"
}
puts "*********************************************"
puts "  bitstream in $rundir/${top}_wrapper.bit"
puts "  resource utilization report in $rundir/${top}_wrapper_utilization_placed.rpt"
puts "  timing report in $rundir/${top}_wrapper_timing_summary_routed.rpt"
puts "*********************************************"
