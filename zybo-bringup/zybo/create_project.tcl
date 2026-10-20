# create_project.tcl - builds the Vivado project for the Zybo Z7-10 (PL only)
#
# Vivado Tcl Console:
#   cd C:/path/to/zybo-bringup/zybo
#   source create_project.tcl
# Then: Generate Bitstream -> Open Hardware Manager -> Program Device
#
# The generated project lives in zybo/vivado/ (git-ignored). Sources stay in
# rtl/, constr/ and sim/, so you can delete vivado/ and re-run this any time.

set proj_dir [file normalize [file dirname [info script]]]

create_project zybo_bringup $proj_dir/vivado -part xc7z010clg400-1 -force

add_files -norecurse [glob $proj_dir/rtl/*.sv]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sources_1] *.sv]
set_property top top [current_fileset]

add_files -fileset constrs_1 -norecurse $proj_dir/constr/zybo_z7_10.xdc

add_files -fileset sim_1 -norecurse [glob $proj_dir/sim/*.sv]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] *.sv]
set_property top tb_top [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
puts "Project created in $proj_dir/vivado"
