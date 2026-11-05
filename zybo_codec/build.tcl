# Non-project build. From this folder:
#   vivado -mode batch -source build.tcl
# or in the Vivado Tcl console (no project open): cd <this folder>; source build.tcl

file mkdir build
read_verilog [glob rtl/*.v]
read_xdc zybo_codec.xdc

synth_design -top zybo_codec_top -part xc7z010clg400-1
opt_design
place_design
route_design
report_timing_summary -file build/timing.rpt
write_bitstream -force build/zybo_codec_top.bit
