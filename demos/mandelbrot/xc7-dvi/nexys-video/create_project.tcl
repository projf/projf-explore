# Project F: Vivado Project Creation Script: Nexys Video
# (C)2023 Will Green, open source hardware released under the MIT License

# project settings
set projf_project_name "mandelbrot"
set projf_arch "xc7-dvi"
set projf_board_name "nexys-video"
set projf_fpga_part "xc7a200tsbg484-1"

puts "INFO: Project F: ${projf_project_name} (${projf_board_name})"

# set reference directories for source files
set lib_dir [file normalize "./../../../../lib"]
set origin_dir [file normalize "./../../"]

puts "INFO: Library directory: ${lib_dir}"
puts "INFO: Origin directory:  ${origin_dir}"

# set project directory
set orig_proj_dir "[file normalize "${origin_dir}/${projf_arch}/${projf_board_name}"]"

# create Vivado project
create_project ${projf_project_name} ${orig_proj_dir} -part ${projf_fpga_part}

#
# design sources - project specific
#

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set fs_design_obj [get_filesets sources_1]

# top design sources (not used in simulation)
set top_sources [list \
  [file normalize "${origin_dir}/${projf_arch}/top_mandel.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $top_sources
set design_top_obj [get_files -of_objects [get_filesets sources_1]]
set_property -name "used_in_simulation" -value "0" -objects $design_top_obj

# set top module for design sources
set_property -name "top" -value "top_mandel" -objects $fs_design_obj
set_property -name "top_auto_set" -value "0" -objects $fs_design_obj

# design sources (used in simulation)
set design_sources [list \
  [file normalize "${lib_dir}/clock/xc7/clock_720p.sv"] \
  [file normalize "${lib_dir}/clock/xc7/clock_sys.sv"] \
  [file normalize "${lib_dir}/clock/xd.sv"] \
  [file normalize "${lib_dir}/display/bitmap_addr.sv"] \
  [file normalize "${lib_dir}/display/display_720p.sv"] \
  [file normalize "${lib_dir}/display/linebuffer_simple.sv"] \
  [file normalize "${lib_dir}/display/tmds_encoder_dvi.sv"] \
  [file normalize "${lib_dir}/display/xc7/dvi_generator.sv"] \
  [file normalize "${lib_dir}/display/xc7/oserdes_10b.sv"] \
  [file normalize "${lib_dir}/display/xc7/tmds_out.sv"] \
  [file normalize "${lib_dir}/essential/xc7/async_reset.sv"] \
  [file normalize "${lib_dir}/essential/debounce.sv"] \
  [file normalize "${lib_dir}/maths/mul.sv"] \
  [file normalize "${lib_dir}/memory/bram_sdp.sv"] \
  [file normalize "${origin_dir}/render_mandel.sv"] \
  [file normalize "${origin_dir}/mandelbrot.sv"] \
]
add_files -norecurse -fileset $fs_design_obj $design_sources

#
# constraints
#

# create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set fs_constr_obj [get_filesets constrs_1]

set constr_sources [list \
  [file normalize "$origin_dir/${projf_arch}/${projf_board_name}/${projf_board_name}.xdc"] \
]
add_files -norecurse -fileset $fs_constr_obj $constr_sources
set constr_file_obj [get_files -of_objects [get_filesets constrs_1]]
set_property -name "file_type" -value "XDC" -objects $constr_file_obj

#
# done
#

puts "INFO: Project created: ${projf_project_name} (${projf_board_name})"

# unset Project F variables
unset projf_fpga_part
unset projf_board_name
unset projf_arch
unset projf_project_name
