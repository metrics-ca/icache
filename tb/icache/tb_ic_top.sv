// Testbench for ic_top
module tb_ic_top;

import uvm_pkg::*;
import tb_icache_pkg::*;

wire            clk;
reg             rst_n;

reg             sch_ic_go;
reg [26:1]      sch_ic_pc;

logic [2:0]     ic_cpu_ctx_q3;
logic [26:1]    ic_cpu_pc_q3;
logic [31:0]    ic_cpu_insn_q3;
logic           ic_cpu_ctx_en_q3;

logic [4:0]     ic_cpu_ra_n3;    
logic           ic_cpu_ra_en_n3; 
logic [4:0]     ic_cpu_rb_n3;   
logic           ic_cpu_rb_en_n3;
logic [4:0]     ic_cpu_rd_q3;
logic           ic_cpu_rd_en_q3;

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

ic_top dut(.*);

bind ic_ctrl ic_ctrl_cover u_cover(.*);

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
    repeat (4) @(posedge clk);
    rst_n <= 1'b1;
end

// Interim "fake CPU"
logic [2:0]     ic_cpu_ctx_q4;
logic [2:0]     ic_cpu_ctx_q5;
logic [26:1]    ic_cpu_pc_q4;
logic [26:1]    ic_cpu_pc_q5;
logic [31:0]    ic_cpu_insn_q4;
logic [31:0]    ic_cpu_insn_q5;
logic           ic_cpu_ctx_en_q4;
logic           ic_cpu_ctx_en_q5;
logic           start, running, start_ack;
logic [26:1]    start_pc;

always @(posedge clk) begin
    ic_cpu_ctx_q4 <= ic_cpu_ctx_q3;     // output of RF
    ic_cpu_ctx_q5 <= ic_cpu_ctx_q4;     // output of ALU
    ic_cpu_ctx_en_q4 <= ic_cpu_ctx_en_q3; // output of RF
    ic_cpu_ctx_en_q5 <= ic_cpu_ctx_en_q4; // output of ALU
    ic_cpu_insn_q4 <= ic_cpu_insn_q3;   // output of RF
    ic_cpu_insn_q5 <= ic_cpu_insn_q4;   // output of ALU
    ic_cpu_pc_q4 <= ic_cpu_pc_q3;       // output of RF
    ic_cpu_pc_q5 <= ic_cpu_pc_q4;       // output of ALU
    start_ack <= start & (!ic_cpu_ctx_q5);
end

wire [1:0]      insn_sz = (ic_cpu_insn_q5[1:0] == 2'b11) ? 2 : 1;

always @*
    if (start) begin
        sch_ic_pc = start_pc;
        sch_ic_go = 1;
    end else begin
        sch_ic_pc = ic_cpu_pc_q5 + insn_sz;
        sch_ic_go = ic_cpu_ctx_en_q5;
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