## Project F: Hello Nexys C - Board Constraints
## (C)2020 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Slide Switches
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS12} [get_ports {sw[0]}];
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS12} [get_ports {sw[1]}];

## LEDs
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {led[0]}];
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {led[1]}];
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS25} [get_ports {led[2]}];
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS25} [get_ports {led[3]}];
