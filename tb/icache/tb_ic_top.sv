// Testbench for ic_top
module tb_ic_top;

import uvm_pkg::*;
import tb_icache_pkg::*;

wire            clk;
reg             rst_n;

wire [26:4]     ic_mem_addr;
wire [1:0]      ic_mem_xid;
wire            ic_mem_re;
reg             mem_ic_ready;
reg             mem_ic_valid;
reg [1:0]       mem_ic_xid;
reg [127:0]     mem_ic_data;

assign #5ns clk = (clk === 1'b0);

ic_fetch_if fetch_if(.*);
dram_ctrl_if dram_if(.*);

ic_top dut(
    .fetch_addr(fetch_if.fetch_addr),
    .fetch_en(fetch_if.fetch_en),
    .fetch_valid(fetch_if.fetch_valid),
    .fetch_data(fetch_if.fetch_data),
    .*);

assign fetch_if.init_done = dut.u_ctrl.init_done;

dram_arb arb(
    .mem_xxx_xid(mem_ic_xid),
    .mem_xxx_data(mem_ic_data),
    .ddr_cmd(dram_if.ddr_cmd),
    .ddr_cmd_en(dram_if.ddr_cmd_en),
    .ddr_addr(dram_if.ddr_addr),
    .ddr_wr_data(dram_if.ddr_wr_data),
    .ddr_wr_data_mask(dram_if.ddr_wr_data_mask),
    .ddr_wr_data_en(dram_if.ddr_wr_data_en),
    .ddr_cmd_ready(dram_if.ddr_cmd_ready),
    .ddr_rd_data(dram_if.ddr_rd_data),
    .ddr_rd_data_valid(dram_if.ddr_rd_data_valid),
    .*);

gowin_ddr_model ddr_model(
    .ddr_calib_done(ddr_calib_done),
    .ddr_cmd(dram_if.ddr_cmd),
    .ddr_cmd_en(dram_if.ddr_cmd_en),
    .ddr_addr(dram_if.ddr_addr),
    .ddr_wr_data(dram_if.ddr_wr_data),
    .ddr_wr_data_mask(dram_if.ddr_wr_data_mask),
    .ddr_wr_data_en(dram_if.ddr_wr_data_en),
    .ddr_cmd_ready(dram_if.ddr_cmd_ready),
    .ddr_rd_data(dram_if.ddr_rd_data),
    .ddr_rd_data_valid(dram_if.ddr_rd_data_valid),
    .*);

initial begin
    rst_n = 1'b0;
    fetch_if.fetch_en = 1'b0;
    repeat (4) @(posedge clk);
    rst_n <= 1'b1;
end

initial begin
    uvm_config_db#(virtual ic_fetch_if)::set(null, "*", "vif", fetch_if);
    uvm_config_db#(virtual dram_ctrl_if)::set(null, "*", "vif", dram_if);
    run_test();
end

initial begin
    #10ms;
    $display("Watchdog timeout!");
    $finish;
end
endmodule