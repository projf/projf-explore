cmake_minimum_required(VERSION 3.19)
project(fpga-graphics)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
find_package(SDL2 REQUIRED)

add_executable(square main_square.cpp)
verilate(square SOURCES top_square.sv INCLUDE_DIRS ..)
target_link_libraries(square PRIVATE SDL2::Main)

add_executable(beam main_beam.cpp)
verilate(beam SOURCES top_beam.sv INCLUDE_DIRS ..)
target_link_libraries(beam PRIVATE SDL2::Main)

add_executable(bounce main_bounce.cpp)
verilate(bounce SOURCES top_bounce.sv INCLUDE_DIRS ..)
target_link_libraries(bounce PRIVATE SDL2::Main)
