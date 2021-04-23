## Project F: Hello Arty J - Board Constraints
## (C)2020 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Master Clock: 100 MHz
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {clk}];
create_clock -name clk_100m -period 10.00 [get_ports {clk}];

## RGB LEDs
set_property -dict {PACKAGE_PIN G6  IOSTANDARD LVCMOS33} [get_ports {led_r[0]}];
set_property -dict {PACKAGE_PIN F6  IOSTANDARD LVCMOS33} [get_ports {led_g[0]}];
set_property -dict {PACKAGE_PIN E1  IOSTANDARD LVCMOS33} [get_ports {led_b[0]}];
set_property -dict {PACKAGE_PIN G3  IOSTANDARD LVCMOS33} [get_ports {led_r[1]}];
set_property -dict {PACKAGE_PIN J4  IOSTANDARD LVCMOS33} [get_ports {led_g[1]}];
set_property -dict {PACKAGE_PIN G4  IOSTANDARD LVCMOS33} [get_ports {led_b[1]}];
set_property -dict {PACKAGE_PIN J3  IOSTANDARD LVCMOS33} [get_ports {led_r[2]}];
set_property -dict {PACKAGE_PIN J2  IOSTANDARD LVCMOS33} [get_ports {led_g[2]}];
set_property -dict {PACKAGE_PIN H4  IOSTANDARD LVCMOS33} [get_ports {led_b[2]}];
set_property -dict {PACKAGE_PIN K1  IOSTANDARD LVCMOS33} [get_ports {led_r[3]}];
set_property -dict {PACKAGE_PIN H6  IOSTANDARD LVCMOS33} [get_ports {led_g[3]}];
set_property -dict {PACKAGE_PIN K2  IOSTANDARD LVCMOS33} [get_ports {led_b[3]}];
