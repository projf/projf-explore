#!/bin/sh

# Project F: Lint Script
# (C)2021 Will Green, open source software released under the MIT License
# Learn more at https://projectf.io

DIR=`dirname $0`

if [ -d "${DIR}/xc7-hd" ]; then
    echo "## Linting top modules in ${DIR}/xc7-hd"
    for f in ${DIR}/xc7-hd/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/xc7-hd \
            -I${DIR}/../common -I${DIR}/../common/xc7 -I${DIR}/../common/xc7/null \
            -I${DIR}/../common/xc7-tmds -I${DIR}/../common/xc7-tmds/null $f;
    done
fi

if [ -d "${DIR}/xc7" ]; then
    echo "## Linting top modules in ${DIR}/xc7"
    for f in ${DIR}/xc7/top_*\.*v; do
        echo "##   Checking ${f}";
        verilator --lint-only -Wall -I${DIR} -I${DIR}/xc7 \
            -I${DIR}/../common -I${DIR}/../common/xc7 -I${DIR}/../common/xc7/null $f;
    done
fi

# if [ -d "${DIR}/ice40" ]; then
#     echo "## Linting top modules in ${DIR}/ice40"
#     for f in ${DIR}/ice40/top_*\.*v; do
#         echo "##   Checking ${f}";
#         verilator --lint-only -Wall -I${DIR} -I${DIR}/ice40 \
#             -I${DIR}/../common -I${DIR}/../common/ice40 -I${DIR}/../common/ice40/null $f;
#     done
# fi
