# Project F: Create Project F: Beam Vivado Project
# (C)2020 Will Green, Open source hardware released under the MIT License
# Learn more at https://projectf.io/posts/fpga-on-screen/

puts "INFO: Project F - Beam Project Creation Script"

# Set the reference directory for source file relative paths
set origin_dir "./.."

# Set the project name
set _xil_proj_name_ "beam"

# Set the directory path for the project
set orig_proj_dir "[file normalize "$origin_dir/project"]"

# If the FPGA board/part isn't set use the Arty one
if {! [info exists fpga_part]} {
    set fpga_part "xc7a35ticsg324-1L"
}
if {! [info exists board_name]} {
    set board_name "arty"
}

# Create Vivado project
create_project ${_xil_proj_name_} ${orig_proj_dir} -part ${fpga_part}

#
# Design sources
#

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set fs_design_obj [get_filesets sources_1]

# Top design sources (not used in simulation)
set top_sources [list \
  [file normalize "${origin_dir}/top.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $top_sources
set design_top_obj [get_files -of_objects [get_filesets sources_1]]
set_property -name "used_in_simulation" -value "0" -objects $design_top_obj

# Set top module for design sources
set_property -name "top" -value "top" -objects $fs_design_obj
set_property -name "top_auto_set" -value "0" -objects $fs_design_obj

# Design sources (used in simulation)
set design_sources [list \
  [file normalize "${origin_dir}/display_timings.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $design_sources

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
  [file normalize "${origin_dir}/display_timings_tb.sv"] \
]
add_files -norecurse -fileset $fs_sim_obj $sim_sources

# Set 'sim_1' fileset properties
set_property -name "top" -value "display_timings_tb" -objects $fs_sim_obj
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
  [file normalize "$origin_dir/${board_name}.xdc"] \
]
add_files -norecurse -fileset $fs_constr_obj $constr_sources
set constr_file_obj [get_files -of_objects [get_filesets constrs_1]]
set_property -name "file_type" -value "XDC" -objects $constr_file_obj

#
# Done
#

puts "INFO: Project created:${_xil_proj_name_}"
