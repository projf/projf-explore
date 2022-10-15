#!/bin/sh

# Project F: Lint Script (XC7 with local display lib)
# (C)2022 Will Green, open source software released under the MIT License
# Learn more at https://projectf.io

DIR=`dirname $0`
LIB="${DIR}/../../lib"

# Xilinx 7 Series
if [ -d "${DIR}/xc7" ]; then
    echo "## Linting top modules in ${DIR}/xc7"
    for f in ${DIR}/xc7/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/lib/display -I${DIR}/xc7 \
            -I${LIB}/clock     -I${LIB}/clock/xc7 \
            -I${LIB}/display   -I${LIB}/display/xc7 \
            -I${LIB}/essential -I${LIB}/essential/xc7 \
            -I${LIB}/graphics  -I${LIB}/graphics/xc7 \
            -I${LIB}/maths     -I${LIB}/maths/xc7 \
            -I${LIB}/memory    -I${LIB}/memory/xc7 \
            -I${LIB}/null/xc7 $f;
    done
fi
