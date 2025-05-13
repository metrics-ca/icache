#!/usr/bin/env sh
uvm=${1:-1.2}

dvlcom -F ../rtl/icache/icache.f
dvlcom -uvm $uvm -F ../tb/dram_ctrl/dram_ctrl.f
dvlcom ../tb/icache/tb_ic_top.sv
dvlcom -uvm $uvm -F ../tb/icache/tb_icache.f
dvlcom ../rtl/top/dram_arb.sv
dvlcom ../tb/icache/ic_ctrl_cover.sv

dsim -top work.tb_ic_top -genimage image -separate-unit-scopes  -uvm $uvm +acc+b -L gowin -j 8
dsim -image image -uvm $uvm -waves ic.mxd +UVM_TESTNAME=ic_stress_test
