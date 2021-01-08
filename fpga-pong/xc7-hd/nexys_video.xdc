## Project F: FPGA Pong - Nexys Video Board Constraints
## (C)2021 Will Green, Open source hardware released under the MIT License
## Learn more at https://projectf.io

## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Master Clock: 100 MHz
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports {clk_100m}];
create_clock -period 10.000 -name clk_100m [get_ports {clk_100m}];

# ## Pixel clock is async to system clock
# set_clock_groups -name SysPixel -asynchronous \
#     -group [get_clocks -of_objects [get_pins clock_sys_inst/MMCME2_BASE_inst/CLKOUT0]] \
#     -group [get_clocks -of_objects [get_pins clock_pix_inst/MMCME2_BASE_inst/CLKOUT1]];

## Buttons
set_property -dict {PACKAGE_PIN G4  IOSTANDARD LVCMOS15} [get_ports {btn_rst}];
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS12} [get_ports {btn_up}];
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS12} [get_ports {btn_ctrl}]; # centre
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS12} [get_ports {btn_dn}];

## HDMI Source
set_property -dict {PACKAGE_PIN T1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_p}];
set_property -dict {PACKAGE_PIN U1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_clk_n}];
set_property -dict {PACKAGE_PIN W1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_p}];
set_property -dict {PACKAGE_PIN Y1  IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch0_n}];
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_p}];
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch1_n}];
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_p}];
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_ch2_n}];
