# Project F: Racing the Beam - Create Vivado Project (Nexys Video)
# (C)2022 Will Green, open source hardware released under the MIT License
# Learn more at https://projectf.io/posts/racing-the-beam/

puts "INFO: Project F - Racing the Beam Project Creation Script"

# If the FPGA board/part isn't set use Nexys Video
if {! [info exists fpga_part]} {
    set projf_fpga_part "xc7a200tsbg484-1"
} else {
    set projf_fpga_part ${fpga_part}
}
if {! [info exists board_name]} {
    set projf_board_name "nexys_video"
} else {
    set projf_board_name ${board_name}
}

# Set the project name
set _xil_proj_name_ "racing-the-beam-hd"

# Set the reference directories for source file relative paths
set lib_dir [file normalize "./../../../../lib"]
set origin_dir [file normalize "./../../"]

puts "INFO: Library directory: ${lib_dir}"
puts "INFO: Origin directory:  ${origin_dir}"

# Set the directory path for the project
set orig_proj_dir "[file normalize "${origin_dir}/xc7-hd/vivado"]"

# Create Vivado project
create_project ${_xil_proj_name_} ${orig_proj_dir} -part ${projf_fpga_part}

#
# Design sources
#

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set fs_design_obj [get_filesets sources_1]

# Top design sources (not used in simulation)
set top_sources [list \
  [file normalize "${origin_dir}/xc7-hd/top_bounce.sv"] \
  [file normalize "${origin_dir}/xc7-hd/top_colour_cycle.sv"] \
  [file normalize "${origin_dir}/xc7-hd/top_hello.sv"] \
  [file normalize "${origin_dir}/xc7-hd/top_hitomezashi.sv"] \
  [file normalize "${origin_dir}/xc7-hd/top_rasterbars.sv"] \

]
add_files -norecurse -fileset $fs_design_obj $top_sources
set design_top_obj [get_files -of_objects [get_filesets sources_1]]
set_property -name "used_in_simulation" -value "0" -objects $design_top_obj

set_property -name "top" -value "top_rasterbars" -objects $fs_design_obj
set_property -name "top_auto_set" -value "0" -objects $fs_design_obj

# Design sources (used in simulation)
set design_sources [list \
  [file normalize "${lib_dir}/clock/xc7/clock_720p.sv"] \
  [file normalize "${lib_dir}/display/tmds_encoder_dvi.sv"] \
  [file normalize "${lib_dir}/display/xc7/dvi_generator.sv"] \
  [file normalize "${lib_dir}/display/xc7/oserdes_10b.sv"] \
  [file normalize "${lib_dir}/display/xc7/tmds_out.sv"] \
  [file normalize "${lib_dir}/essential/xc7/async_reset.sv"] \
  [file normalize "${origin_dir}/simple_720p.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $design_sources

#
# Constraints
#

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set fs_constr_obj [get_filesets constrs_1]

set constr_sources [list \
  [file normalize "$origin_dir/xc7-hd/${projf_board_name}.xdc"] \
]
add_files -norecurse -fileset $fs_constr_obj $constr_sources
set constr_file_obj [get_files -of_objects [get_filesets constrs_1]]
set_property -name "file_type" -value "XDC" -objects $constr_file_obj

# unset Project F variables
unset projf_board_name
unset projf_fpga_part

#
# Done
#

puts "INFO: Project created: ${_xil_proj_name_}"
