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

foreach io [ array names ios ] {
  set port [get_port $io]
  if { [llength $port] != 0 } {
    puts $io
  }
}
    
