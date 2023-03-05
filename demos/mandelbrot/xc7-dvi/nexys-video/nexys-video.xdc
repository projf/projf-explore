## Project F: Board Constraints: Nexys Video
## (C)2023 Will Green, open source hardware released under the MIT License

## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Board Clock: 100 MHz
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports {clk_100m}];
create_clock -name clk_100m -period 10.00 [get_ports {clk_100m}];

## Pixel Clock is async to System Clock
set_clock_groups -name SysPixel -asynchronous \
    -group [get_clocks -of_objects [get_pins clock_sys_inst/MMCME2_BASE_inst/CLKOUT0]] \
    -group [get_clocks -of_objects [get_pins clock_pix_inst/MMCME2_BASE_inst/CLKOUT1]];

## Buttons
set_property -dict {PACKAGE_PIN G4  IOSTANDARD LVCMOS15} [get_ports {btn_rst_n}];
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS12} [get_ports {btn_fire}]; # centre
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS12} [get_ports {btn_up}];
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS12} [get_ports {btn_dn}];

## LEDs
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {led[0]}];
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {led[1]}];
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS25} [get_ports {led[2]}];
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS25} [get_ports {led[3]}];

## HDMI Source
set_property -dict {PACKAGE_PIN T1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_p}];
set_property -dict {PACKAGE_PIN U1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_n}];
set_property -dict {PACKAGE_PIN W1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_p}];
set_property -dict {PACKAGE_PIN Y1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_n}];
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_p}];
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_n}];
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_p}];
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_n}];
