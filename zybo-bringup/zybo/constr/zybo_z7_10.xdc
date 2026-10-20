## Zybo Z7-10 constraints (pin data from Digilent Zybo-Z7-Master.xdc)

## 125 MHz system clock
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports { sysclk }]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }]

## SW0 and LD0..LD3
set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { sw0 }]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports { led[3] }]

## Pmod JE1..JE4 - inputs from the Pico (JE5 = GND)
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { pico_in[0] }]   ;# JE1
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports { pico_in[1] }]   ;# JE2
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { pico_in[2] }]   ;# JE3
set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports { pico_in[3] }]   ;# JE4

## Pull-downs so unconnected inputs read 0
set_property PULLDOWN true [get_ports { pico_in[*] }]

## Asynchronous I/O - no timing relationship to sysclk
set_false_path -from [get_ports { pico_in[*] sw0 }]
set_false_path -to   [get_ports { led[*] }]

set_property CFGBVS VCCO        [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
