## Project F: Hardware Sprites - Nexys Video Board Constraints
## (C)2021 Will Green, Open source hardware released under the MIT License
## Learn more at https://projectf.io

## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Board Clock: 100 MHz
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports {clk_100m}];
create_clock -name clk_100m -period 10.00 [get_ports {clk_100m}];

## Buttons
set_property -dict {PACKAGE_PIN G4  IOSTANDARD LVCMOS15} [get_ports {btn_rst}];

## HDMI Source
set_property -dict {PACKAGE_PIN T1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_p}];
set_property -dict {PACKAGE_PIN U1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_n}];
set_property -dict {PACKAGE_PIN W1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_p}];
set_property -dict {PACKAGE_PIN Y1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_n}];
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_p}];
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_n}];
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_p}];
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_n}];
