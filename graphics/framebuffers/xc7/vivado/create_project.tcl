# Project F: Framebuffers - Create Vivado Project
# (C)2021 Will Green, open source hardware released under the MIT License
# Learn more at https://projectf.io

puts "INFO: Project F - Framebuffers Project Creation Script"

# If the FPGA board/part isn't set use Arty
if {! [info exists fpga_part]} {
    set projf_fpga_part "xc7a35ticsg324-1L"
} else {
    set projf_fpga_part ${fpga_part}
}
if {! [info exists board_name]} {
    set projf_board_name "arty"
} else {
    set projf_board_name ${board_name}
}

# Set the project name
set _xil_proj_name_ "framebuffers"

# Set the reference directories for source file relative paths
set lib_dir [file normalize "./../../../../lib"]
set origin_dir [file normalize "./../../"]

puts "INFO: Library directory: ${lib_dir}"
puts "INFO: Origin directory:  ${origin_dir}"

# Set the directory path for the project
set orig_proj_dir "[file normalize "${origin_dir}/xc7/vivado"]"

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
  [file normalize "${origin_dir}/xc7/top_david_v1.sv"] \
  [file normalize "${origin_dir}/xc7/top_david_v2.sv"] \
  [file normalize "${origin_dir}/xc7/top_david_v3.sv"] \
  [file normalize "${origin_dir}/xc7/top_david.sv"] \
  [file normalize "${origin_dir}/xc7/top_line.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $top_sources
set design_top_obj [get_files -of_objects [get_filesets sources_1]]
set_property -name "used_in_simulation" -value "0" -objects $design_top_obj

# Set top module for design sources
set_property -name "top" -value "top_david" -objects $fs_design_obj
set_property -name "top_auto_set" -value "0" -objects $fs_design_obj

# Design sources (used in simulation)
set design_sources [list \
  [file normalize "${lib_dir}/clock/xc7/clock_gen_480p.sv"] \
  [file normalize "${lib_dir}/clock/xd.sv"] \
  [file normalize "${lib_dir}/display/display_480p.sv"] \
  [file normalize "${lib_dir}/display/framebuffer_bram.sv"] \
  [file normalize "${lib_dir}/display/linebuffer.sv"] \
  [file normalize "${lib_dir}/maths/lfsr.sv"] \
  [file normalize "${lib_dir}/memory/rom_async.sv"] \
  [file normalize "${lib_dir}/memory/xc7/bram_sdp.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $design_sources

# Memory design sources
set mem_design_sources [list \
  [file normalize "${lib_dir}/res/test/test_box_12x9.mem"] \
  [file normalize "${lib_dir}/res/test/test_box_160x120.mem"] \
  [file normalize "${lib_dir}/res/test/test_box_mono_160x120.mem"] \
  [file normalize "${lib_dir}/res/test/test_palette.mem"] \
  [file normalize "${origin_dir}/res/david/david.mem"] \
  [file normalize "${origin_dir}/res/david/david_test.mem"] \
  [file normalize "${origin_dir}/res/david/david_palette.mem"] \
  [file normalize "${origin_dir}/res/david/david_palette_warm.mem"] \
  [file normalize "${origin_dir}/res/david/david_palette_invert.mem"] \
  [file normalize "${origin_dir}/res/david/david_1bit.mem"] \
]
add_files -norecurse -fileset $fs_design_obj $mem_design_sources
set design_mem_obj [get_files -of_objects [get_filesets sources_1] [list "*mem"]]
set_property -name "file_type" -value "Memory File" -objects $design_mem_obj

#
# Simulation Sources
#

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}
set fs_sim_obj [get_filesets sim_1]

# Generic simulation sources
set sim_sources [list \
  [file normalize "${lib_dir}/clock/xc7/xd_tb.sv"] \
  [file normalize "${lib_dir}/clock/xc7/vivado/xd_tb_behav.wcfg" ] \
  [file normalize "${lib_dir}/display/display_timings_24x18.sv"] \
  [file normalize "${lib_dir}/display/xc7/framebuffer_bram_tb.sv"] \
  [file normalize "${lib_dir}/display/xc7/linebuffer_tb.sv"] \
  [file normalize "${lib_dir}/display/xc7/vivado/framebuffer_bram_tb_behav.wcfg" ] \
  [file normalize "${lib_dir}/display/xc7/vivado/linebuffer_tb_behav.wcfg" ] \
]
add_files -norecurse -fileset $fs_sim_obj $sim_sources

# Set 'sim_1' fileset properties
set_property -name "top" -value "linebuffer_tb" -objects $fs_sim_obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $fs_sim_obj

#
# Constraints
#

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set fs_constr_obj [get_filesets constrs_1]

set constr_sources [list \
  [file normalize "$origin_dir/xc7/${projf_board_name}.xdc"] \
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
