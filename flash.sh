#!/usr/bin/env bash

rm -rf $1/top.sdk

mkdir $1/top.sdk

cp $1/top.runs/impl_1/top_wrapper.sysdef $1/top.sdk/top_wrapper.hdf

hw_server -s TCP:localhost:3121&

xsct -interactive $1/../scripts/sdk.tcl "$2"

#xsdk -workspace $1/top.sdk -hwspec $1/top.sdk/top_wrapper.hdf
