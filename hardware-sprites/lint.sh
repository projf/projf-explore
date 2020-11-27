#!/bin/sh

# Project F: Lint Script
# (C)2020 Will Green, open source software released under the MIT License
# Learn more at https://projectf.io

DIR=`dirname $0`

echo "## Linting top modules in ${DIR}/xc7"
for f in ${DIR}/xc7/top_*.sv; do
    echo "##   Checking ${f}";
    verilator -Wall --lint-only -I${DIR} -I${DIR}/xc7 \
        -I${DIR}/../common -I${DIR}/../common/xc7 -I${DIR}/../common/xc7/null $f;
done

echo "## Linting top modules in ${DIR}/ice40"
for f in ${DIR}/ice40/top_*.sv; do
    echo "##   Checking ${f}";
    verilator -Wall --lint-only -I${DIR} -I${DIR}/ice40 \
        -I${DIR}/../common -I${DIR}/../common/ice40 -I${DIR}/../common/ice40/null $f;
done
