## Project F: FPGA Graphics - Arty S7-25 Board Constraints (DVI)
## (C)2023 Will Green, Open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/fpga-graphics/

## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Board Clock: 100 MHz
set_property -dict {PACKAGE_PIN R2 IOSTANDARD SSTL135} [get_ports {clk_100m}];
create_clock -name clk_100m -period 10.00 [get_ports {clk_100m}];

## Buttons
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports {btn_rst_n}];

## HDMI Source
set_property -dict {PACKAGE_PIN T18 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_p}];
set_property -dict {PACKAGE_PIN P16 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_n}];
set_property -dict {PACKAGE_PIN R18 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_p}];
set_property -dict {PACKAGE_PIN N15 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_n}];
set_property -dict {PACKAGE_PIN P18 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_p}];
set_property -dict {PACKAGE_PIN P15 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_n}];
set_property -dict {PACKAGE_PIN P17 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_p}];
set_property -dict {PACKAGE_PIN P14 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_n}];
