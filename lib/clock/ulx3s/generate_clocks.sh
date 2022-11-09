#!/bin/bash

# (C) 2022 Tristan Itschner
# SPDX-License-Identifier: D-FSL-1.0

CLKIN_NAME=clk_25m
CLKIN=25

clocks=(480p 25 720p 75 1080p30hz 79.75)

for i in $(seq 1 $(("${#clocks[@]}"/2))) ; do
	name="${clocks[$((2*(i - 1)))]}"
	freq="${clocks[$((2*(i - 1) + 1))]}"
	freq_tmds_half=$(echo "$freq*5.0" | bc)
	cmd="ecppll -n clock_$name -f clock_$name.v \
	--clkin   $CLKIN          --clkin_name   $CLKIN_NAME   \
	--clkout0 $freq_tmds_half --clkout0_name clk_tmds_half \
	--clkout1 $freq           --clkout1_name clk_pix"
	echo "$cmd"
	$cmd
done
