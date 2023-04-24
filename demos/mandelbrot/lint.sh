#!/bin/sh

# Project F: Lint Script
# (C)2023 Will Green, open source software released under the MIT License
# Learn more at https://projectf.io/posts/verilog-lint-with-verilator/

DIR=`dirname $0`
LIB="${DIR}/../../lib"

# Verilator Simulation
if [ -d "${DIR}/verilator-sdl" ]; then
    echo "## Linting top modules in ${DIR}/verilator-sdl"
    for f in ${DIR}/verilator-sdl/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/verilator-sdl \
            -I${LIB}/clock \
            -I${LIB}/display \
            -I${LIB}/essential \
            -I${LIB}/graphics \
            -I${LIB}/maths \
            -I${LIB}/memory $f;
    done
fi

# Lattice iCE40
if [ -d "${DIR}/ice40" ]; then
    echo "## Linting top modules in ${DIR}/ice40"
    for f in ${DIR}/ice40/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/ice40 \
            -I${LIB}/clock     -I${LIB}/clock/ice40 \
            -I${LIB}/display   -I${LIB}/display/ice40 \
            -I${LIB}/essential -I${LIB}/essential/ice40 \
            -I${LIB}/graphics  -I${LIB}/graphics/ice40 \
            -I${LIB}/maths     -I${LIB}/maths/ice40 \
            -I${LIB}/memory    -I${LIB}/memory/ice40 \
            -I${LIB}/null/ice40 $f;
    done
fi

# Xilinx 7 Series (VGA Output)
if [ -d "${DIR}/xc7-vga" ]; then
    echo "## Linting top modules in ${DIR}/xc7-vga"
    for f in ${DIR}/xc7-vga/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/xc7-vga \
            -I${LIB}/clock     -I${LIB}/clock/xc7 \
            -I${LIB}/display   -I${LIB}/display/xc7 \
            -I${LIB}/essential -I${LIB}/essential/xc7 \
            -I${LIB}/graphics  -I${LIB}/graphics/xc7 \
            -I${LIB}/maths     -I${LIB}/maths/xc7 \
            -I${LIB}/memory    -I${LIB}/memory/xc7 \
            -I${LIB}/null/xc7 $f;
    done
fi

# Xilinx 7 Series (DVI Output)
if [ -d "${DIR}/xc7-dvi" ]; then
    echo "## Linting top modules in ${DIR}/xc7-dvi"
    for f in ${DIR}/xc7-dvi/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/xc7-dvi \
            -I${LIB}/clock     -I${LIB}/clock/xc7 \
            -I${LIB}/display   -I${LIB}/display/xc7 \
            -I${LIB}/essential -I${LIB}/essential/xc7 \
            -I${LIB}/graphics  -I${LIB}/graphics/xc7 \
            -I${LIB}/maths     -I${LIB}/maths/xc7 \
            -I${LIB}/memory    -I${LIB}/memory/xc7 \
            -I${LIB}/null/xc7 $f;
    done
fi
