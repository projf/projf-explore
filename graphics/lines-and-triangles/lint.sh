#!/bin/sh

# Project F: Lint Script
# (C)2021 Will Green, open source software released under the MIT License
# Learn more at https://projectf.io

DIR=`dirname $0`
LIB="${DIR}/../../lib"

if [ -d "${DIR}/xc7-hd" ]; then
    echo "## Linting top modules in ${DIR}/xc7-hd"
    for f in ${DIR}/xc7-hd/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/xc7-hd \
            -I${LIB}/clock     -I${LIB}/clock/xc7 \
            -I${LIB}/display   -I${LIB}/display/xc7 \
            -I${LIB}/essential -I${LIB}/essential/xc7 \
            -I${LIB}/maths     -I${LIB}/maths/xc7 \
            -I${LIB}/memory    -I${LIB}/memory/xc7 \
            -I${LIB}/null/xc7 $f;
    done
fi

if [ -d "${DIR}/xc7" ]; then
    echo "## Linting top modules in ${DIR}/xc7"
    for f in ${DIR}/xc7/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/xc7 \
            -I${LIB}/clock     -I${LIB}/clock/xc7 \
            -I${LIB}/display   -I${LIB}/display/xc7 \
            -I${LIB}/essential -I${LIB}/essential/xc7 \
            -I${LIB}/maths     -I${LIB}/maths/xc7 \
            -I${LIB}/memory    -I${LIB}/memory/xc7 \
            -I${LIB}/null/xc7 $f;
    done
fi

if [ -d "${DIR}/ice40" ]; then
    echo "## Linting top modules in ${DIR}/ice40"
    for f in ${DIR}/ice40/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/ice40 \
            -I${LIB}/clock     -I${LIB}/clock/ice40 \
            -I${LIB}/display   -I${LIB}/display/ice40 \
            -I${LIB}/essential -I${LIB}/essential/ice40 \
            -I${LIB}/maths     -I${LIB}/maths/ice40 \
            -I${LIB}/memory    -I${LIB}/memory/ice40 \
            -I${LIB}/null/ice40 $f;
    done
fi

