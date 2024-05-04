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

logic           ddr_calib_done;
logic [2:0]     ddr_cmd;
logic           ddr_cmd_en;
logic [27:0]    ddr_addr;
logic [127:0]   ddr_wr_data;
logic [15:0]    ddr_wr_data_mask;
logic           ddr_wr_data_en;
logic           ddr_cmd_ready;
logic [127:0]   ddr_rd_data;
logic           ddr_rd_data_valid;

assign #5ns clk = (clk === 1'b0);

ic_fetch_if fetch_if(.*);
ic_top dut(
    .fetch_addr(fetch_if.fetch_addr),
    .fetch_en(fetch_if.fetch_en),
    .fetch_valid(fetch_if.fetch_valid),
    .fetch_data(fetch_if.fetch_data),
    .*);

dram_arb arb(
    .mem_xxx_xid(mem_ic_xid),
    .mem_xxx_data(mem_ic_data),
    .*);

gowin_ddr_model ddr_model(
    .*);

initial begin
    rst_n = 1'b0;
    fetch_if.fetch_en = 1'b0;
    repeat (4) @(posedge clk);
    rst_n <= 1'b1;
end

initial begin
    uvm_config_db#(virtual ic_fetch_if)::set(null, "*", "vif", fetch_if);
    run_test();
end

endmodule