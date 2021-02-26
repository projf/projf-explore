# Project F: Lines and Triangles - Create Vivado Project (Nexys Video)
# (C)2021 Will Green, open source hardware released under the MIT License
# Learn more at https://projectf.io

puts "INFO: Project F - Lines and Triangles Project Creation Script"

# If the FPGA board/part isn't set use Nexys Video
if {! [info exists fpga_part]} {
    set fpga_part "xc7a200tsbg484-1"
}
if {! [info exists board_name]} {
    set board_name "nexys_video"
}

# Set the project name
set _xil_proj_name_ "lines-and-triangles-hd"

# Set the reference directories for source file relative paths
set origin_dir [file normalize "./../../"]
set common_dir [file normalize "./../../../common"]

# Set the directory path for the project
set orig_proj_dir "[file normalize "${origin_dir}/xc7-hd/vivado"]"

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
  [file normalize "${origin_dir}/xc7-hd/top_cube.sv"] \
  [file normalize "${origin_dir}/xc7-hd/top_line.sv"] \
  [file normalize "${origin_dir}/xc7-hd/top_triangles.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $top_sources
set design_top_obj [get_files -of_objects [get_filesets sources_1]]
set_property -name "used_in_simulation" -value "0" -objects $design_top_obj

# Set top module for design sources
set_property -name "top" -value "top_triangles" -objects $fs_design_obj
set_property -name "top_auto_set" -value "0" -objects $fs_design_obj

# Design sources (used in simulation)
set design_sources [list \
  [file normalize "${common_dir}/display_timings_720p.sv"] \
  [file normalize "${common_dir}/linebuffer.sv"] \
  [file normalize "${common_dir}/rom_async.sv"] \
  [file normalize "${common_dir}/tmds_encoder_dvi.sv"] \
  [file normalize "${common_dir}/xd.sv"] \
  [file normalize "${common_dir}/xc7/async_reset.sv"] \
  [file normalize "${common_dir}/xc7/bram_sdp.sv"] \
  [file normalize "${common_dir}/xc7-hd/clock_gen_pix.sv"] \
  [file normalize "${common_dir}/xc7-hd/dvi_generator.sv"] \
  [file normalize "${common_dir}/xc7-hd/oserdes_10b.sv"] \
  [file normalize "${common_dir}/xc7-hd/tmds_out.sv"] \
  [file normalize "${origin_dir}/draw_line.sv"] \
  [file normalize "${origin_dir}/draw_triangle.sv"] \
  [file normalize "${origin_dir}/pix_addr.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $design_sources

# Memory design sources
set mem_design_sources [list \
  [file normalize "${common_dir}/res/test/test_clear_12x9.mem"] \
  [file normalize "${common_dir}/res/test/test_palette.mem"] \
  [file normalize "${origin_dir}/res/palette/16_colr_8bit_palette.mem"] \
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
  [file normalize "${common_dir}/display_timings_24x18.sv"] \
  [file normalize "${origin_dir}/xc7/draw_framebuffer_tb.sv"] \
  [file normalize "${origin_dir}/xc7/draw_line_tb.sv"] \
  [file normalize "${origin_dir}/xc7/draw_triangle_tb.sv"] \
  [file normalize "${origin_dir}/xc7/vivado/draw_framebuffer_tb_behav.wcfg"] \
  [file normalize "${origin_dir}/xc7/vivado/draw_line_tb_behav.wcfg"] \
  [file normalize "${origin_dir}/xc7/vivado/draw_triangle_tb_behav.wcfg"] \
]
add_files -norecurse -fileset $fs_sim_obj $sim_sources

# Set 'sim_1' fileset properties
set_property -name "top" -value "draw_line_tb" -objects $fs_sim_obj
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
  [file normalize "$origin_dir/xc7-hd/${board_name}.xdc"] \
]
add_files -norecurse -fileset $fs_constr_obj $constr_sources
set constr_file_obj [get_files -of_objects [get_filesets constrs_1]]
set_property -name "file_type" -value "XDC" -objects $constr_file_obj

#
# Done
#

puts "INFO: Project created:${_xil_proj_name_}"
