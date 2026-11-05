## Zybo Z7-10, SSM2603 codec bring-up (pins from Digilent Zybo-Z7-Master.xdc)

set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { sw0 }];

set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports { ac_mclk }];
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports { ac_bclk }];
set_property -dict { PACKAGE_PIN T19 IOSTANDARD LVCMOS33 } [get_ports { ac_pblrc }];
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { ac_pbdat }];
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports { ac_reclrc }];
set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 } [get_ports { ac_muten }];
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { ac_scl }];
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { ac_sda }];

## Slow I/O, all generated from MCLK inside the FPGA
set_false_path -to   [get_ports { ac_bclk ac_pblrc ac_reclrc ac_pbdat ac_muten ac_scl ac_sda }]
set_false_path -from [get_ports { ac_sda sw0 }]
