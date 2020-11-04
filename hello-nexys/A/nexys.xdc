## Project F: Hello Nexys A - Board Constraints
## (C)2020 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# I/O Pins
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS12} [get_ports {sw}];
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {led}];
