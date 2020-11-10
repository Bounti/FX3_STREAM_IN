
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
			"sw[0]"         { "F22"  "LVCMOS25" }
			"sw[1]"         { "G22"  "LVCMOS25" }
			"sw[2]"         { "H22"  "LVCMOS25" }
			"sw[3]"         { "F21"  "LVCMOS25" }
			"led[0]"        { "T22"  "LVCMOS33" }
			"led[1]"        { "T21"  "LVCMOS33" }
			"led[2]"        { "U22"  "LVCMOS33" }
			"led[3]"        { "U21"  "LVCMOS33" }
			"btn"           { "T18"  "LVCMOS25" }
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
# Create DMON IP #
###################
create_project -part $part -force dmon dmon
set sources {dmon jtag jtag.pkg}
foreach f $sources {
        add_files $rootdir/hdl/$f.vhd
}
import_files -force -norecurse
ipx::package_project -root_dir dmon -vendor www.eurecom.fr -library DMON -force dmon
close_project

###################
# Create GPIF IP #
###################
create_project -part $part -force gpif gpif
set sources {tristate gpif oddr2}
foreach f $sources {
        add_files $rootdir/hdl/$f.vhd
}
import_files -force -norecurse
ipx::package_project -root_dir gpif -vendor www.eurecom.fr -library GPIF -force gpif
close_project

############################
## Create top level design #
############################
set top top
create_project -part $part -force $top .
set_property board_part $board [current_project]
set_property ip_repo_paths { ./dmon ./gpif } [current_fileset]
update_ip_catalog
create_bd_design "$top"

#set dmon [create_bd_cell -type ip -vlnv [get_ipdefs *www.eurecom.fr:DMON:dmon:*] dmon]
set gpif [create_bd_cell -type ip -vlnv www.eurecom.fr:GPIF:GPIF:1.0 gpif]
set dmon [create_bd_cell -type ip -vlnv www.eurecom.fr:DMON:dmon:1.0 dmon]

create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_0
#create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_2

# configure FIFO
set_property -dict [list CONFIG.Input_Data_Width {32} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {32} CONFIG.Output_Depth {512} CONFIG.Reset_Pin {false} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Use_Dout_Reset {false} CONFIG.Use_Extra_Logic {false} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {510} CONFIG.Full_Threshold_Negate_Value {509}] [get_bd_cells fifo_generator_0]
set_property -dict [list CONFIG.Input_Data_Width {64} CONFIG.Output_Data_Width {32} CONFIG.Output_Depth {1024} CONFIG.Overflow_Flag {true} CONFIG.Use_Extra_Logic {true} CONFIG.Write_Data_Count_Width {10} CONFIG.Read_Data_Count_Width {11} CONFIG.Full_Threshold_Assert_Value {509} CONFIG.Full_Threshold_Negate_Value {508}] [get_bd_cells fifo_generator_0]
set_property -dict [list CONFIG.Write_Acknowledge_Flag {true}] [get_bd_cells fifo_generator_0]
set_property -dict [list CONFIG.Almost_Full_Flag {true} CONFIG.Write_Acknowledge_Flag {false}] [get_bd_cells fifo_generator_0]

make_bd_pins_external [get_bd_pins dmon/aresetn] [get_bd_pins dmon/aclk]

connect_bd_net [get_bd_ports aclk_0] [get_bd_pins axi_vip_2/aclk]
connect_bd_net [get_bd_ports aresetn_0] [get_bd_pins axi_vip_2/aresetn]
#connect_bd_net [get_bd_ports aclk_0] [get_bd_pins axi_vip_1/aclk]
#connect_bd_net [get_bd_ports aresetn_0] [get_bd_pins axi_vip_1/aresetn]
connect_bd_net [get_bd_ports aclk_0] [get_bd_pins fifo_generator_0/clk]

connect_bd_net [get_bd_pins dmon/din] [get_bd_pins fifo_generator_0/din]
connect_bd_net [get_bd_pins dmon/wr_en] [get_bd_pins fifo_generator_0/wr_en]
connect_bd_net [get_bd_pins dmon/full] [get_bd_pins fifo_generator_0/full]
connect_bd_net [get_bd_pins dmon/almost_full] [get_bd_pins fifo_generator_0/almost_full]

connect_bd_net [get_bd_pins gpif/dout] [get_bd_pins  fifo_generator_0/dout]
connect_bd_net [get_bd_pins gpif/rd_en] [get_bd_pins fifo_generator_0/rd_en]
connect_bd_net [get_bd_pins gpif/empty] [get_bd_pins fifo_generator_0/empty]

set_property -dict [list CONFIG.AWUSER_WIDTH.VALUE_SRC USER CONFIG.HAS_RRESP.VALUE_SRC USER CONFIG.HAS_BRESP.VALUE_SRC USER CONFIG.HAS_WSTRB.VALUE_SRC USER CONFIG.HAS_PROT.VALUE_SRC USER CONFIG.HAS_QOS.VALUE_SRC USER CONFIG.HAS_REGION.VALUE_SRC USER CONFIG.HAS_CACHE.VALUE_SRC USER CONFIG.HAS_LOCK.VALUE_SRC USER CONFIG.HAS_BURST.VALUE_SRC USER CONFIG.SUPPORTS_NARROW.VALUE_SRC USER CONFIG.RUSER_BITS_PER_BYTE.VALUE_SRC USER CONFIG.BUSER_WIDTH.VALUE_SRC USER CONFIG.ARUSER_WIDTH.VALUE_SRC USER CONFIG.ID_WIDTH.VALUE_SRC USER CONFIG.DATA_WIDTH.VALUE_SRC USER CONFIG.ADDR_WIDTH.VALUE_SRC USER CONFIG.READ_WRITE_MODE.VALUE_SRC USER CONFIG.PROTOCOL.VALUE_SRC USER] [get_bd_cells axi_vip_2]
set_property -dict [list CONFIG.PROTOCOL {AXI4} CONFIG.INTERFACE_MODE {MASTER} CONFIG.ADDR_WIDTH {30} CONFIG.ID_WIDTH {6} CONFIG.HAS_USER_BITS_PER_BYTE {1} CONFIG.HAS_SIZE {1}] [get_bd_cells axi_vip_2]
connect_bd_intf_net [get_bd_intf_pins axi_vip_2/M_AXI] [get_bd_intf_pins dmon/s1_axi]

#set_property -dict [list CONFIG.HAS_LOCK.VALUE_SRC USER CONFIG.HAS_BURST.VALUE_SRC USER CONFIG.RUSER_BITS_PER_BYTE.VALUE_SRC USER CONFIG.BUSER_WIDTH.VALUE_SRC USER CONFIG.ID_WIDTH.VALUE_SRC USER CONFIG.ADDR_WIDTH.VALUE_SRC USER CONFIG.READ_WRITE_MODE.VALUE_SRC USER CONFIG.PROTOCOL.VALUE_SRC USER CONFIG.HAS_RRESP.VALUE_SRC USER CONFIG.HAS_BRESP.VALUE_SRC USER CONFIG.HAS_WSTRB.VALUE_SRC USER CONFIG.HAS_PROT.VALUE_SRC USER CONFIG.HAS_QOS.VALUE_SRC USER CONFIG.HAS_REGION.VALUE_SRC USER CONFIG.HAS_CACHE.VALUE_SRC USER] [get_bd_cells axi_vip_1]
#set_property -dict [list CONFIG.PROTOCOL {AXI4} CONFIG.INTERFACE_MODE {SLAVE} CONFIG.ADDR_WIDTH {30} CONFIG.ID_WIDTH {6} CONFIG.HAS_USER_BITS_PER_BYTE {1} CONFIG.HAS_SIZE {1} CONFIG.HAS_REGION {0} CONFIG.HAS_ACLKEN {1}] [get_bd_cells axi_vip_1]
#connect_bd_intf_net [get_bd_intf_pins axi_vip_1/S_AXI] [get_bd_intf_pins dmon/m_axi]

connect_bd_net [get_bd_ports aclk_0] [get_bd_pins gpif/aclk]
connect_bd_net [get_bd_ports aresetn_0] [get_bd_pins gpif/aresetn]
make_bd_pins_external  [get_bd_pins gpif/rd_rdy] [get_bd_pins gpif/clk_out] [get_bd_pins gpif/addr] [get_bd_pins gpif/op] [get_bd_pins gpif/data] [get_bd_pins gpif/oe] [get_bd_pins gpif/wr_rdy] [get_bd_pins gpif/status] [get_bd_pins dmon/TDO] [get_bd_pins dmon/TCK] [get_bd_pins dmon/TMS] [get_bd_pins dmon/TDI] [get_bd_pins dmon/TRST] [get_bd_pins dmon/enabled] [get_bd_pins dmon/irq_in] [get_bd_pins dmon/irq_ack] [get_bd_pins dmon/irq_cpu]

validate_bd_design
set files [get_files *$top.bd]
generate_target all $files
add_files -norecurse -force [make_wrapper -files $files -top]
save_bd_design

# Set Address Range
#assign_bd_address [get_bd_addr_segs {axi_vip_1/S_AXI/Reg }]
assign_bd_address [get_bd_addr_segs {dmon/s1_axi/reg0 }]
#set_property offset 0x00000000 [get_bd_addr_segs {dmon/m_axi/SEG_axi_vip_1_Reg}]
#set_property range 2M [get_bd_addr_segs {dmon/m_axi/SEG_axi_vip_1_Reg}]
#set_property range 4G [get_bd_addr_segs {dmon/m_axi/SEG_axi_vip_1_Reg}]

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse $rootdir/tb/tb_react.sv
add_files -fileset sim_1 -norecurse $rootdir/tb/fifo_ram.vhd
update_compile_order -fileset sim_1

generate_target Simulation [get_files /home/nasm/Projects/react/simu/top.srcs/sources_1/bd/top/top.bd]
export_ip_user_files -of_objects [get_files /home/nasm/Projects/react/simu/top.srcs/sources_1/bd/top/top.bd] -no_script -sync -force -quiet
export_simulation -of_objects [get_files /home/nasm/Projects/react/simu/top.srcs/sources_1/bd/top/top.bd] -directory /home/nasm/Projects/react/simu/top.ip_user_files/sim_scripts -ip_user_files_dir /home/nasm/Projects/react/simu/top.ip_user_files -ipstatic_source_dir /home/nasm/Projects/react/simu/top.ip_user_files/ipstatic -lib_map_path [list {modelsim=/home/nasm/Projects/react/simu/top.cache/compile_simlib/modelsim} {questa=/home/nasm/Projects/react/simu/top.cache/compile_simlib/questa} {ies=/home/nasm/Projects/react/simu/top.cache/compile_simlib/ies} {xcelium=/home/nasm/Projects/react/simu/top.cache/compile_simlib/xcelium} {vcs=/home/nasm/Projects/react/simu/top.cache/compile_simlib/vcs} {riviera=/home/nasm/Projects/react/simu/top.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

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
