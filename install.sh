#!/usr/bin/env bash

echo "===================="
echo "Author:  Corteggiani Nassim"
echo "Author:  Davide Balzarotti"
echo "Author:  Aurélien Francillon"
echo "Date:    05/2020"
echo "Version: 0.1"
echo "Name:    ReAct"
echo "===================="

mkdir -p build

vivado -nojournal -nolog -mode batch -source ./scripts/vvsyn.tcl -tclargs $(pwd) $(pwd)/build zed 0

FILE= $(pwd)/build/top.runs/impl_1/top_wrapper.sysdef
if [ -f $FILE ]; then
    ./flash.sh $(pwd)/build 'Hello World'
else
    echo "Synthesis failed..."
fi
