// Testbench for ic_top
module tb_ic_top;

import uvm_pkg::*;
import tb_icache_pkg::*;
import elf_pkg::*;


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
logic           start, start_ack;
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

logic [1:0]     insn_sz;
logic           running;

always @* begin
    if (ic_cpu_ctx_en_q5) begin
        if (ic_cpu_insn_q5[1:0] == 2'b11)
            insn_sz = 2;
        else
            insn_sz= 1;
    end else
        insn_sz = 0;
end

always @(posedge clk) begin
    if (!rst_n) begin
        running <= 0;
        sch_ic_go <= 0;
    end else if (ic_cpu_ctx_q5 == 3'b0) begin
        if (start) begin
            running <= 1;
            sch_ic_pc <= start_pc;
            sch_ic_go <= 1;
        end else begin
            sch_ic_pc <= ic_cpu_pc_q5 + insn_sz;
            sch_ic_go <= running;
        end
    end else begin
        sch_ic_go <= 0;
    end
end

/*
initial begin
    uvm_config_db#(virtual ic_fetch_if)::set(null, "*", "vif", fetch_if);
    uvm_config_db#(virtual dram_ctrl_if)::set(null, "*", "vif", dram_if);
    run_test();
end
*/

initial begin
    automatic ElfFile reader = new;
    automatic bit [63:0] entry;

    start = 0;
    reader.openFile("$HOME/work/riscv-tests/isa/rv64ui-p-addi");
    reader.load(ddr_model.elf_if);
    wait (dut.u_ctrl.init_done == 1);
    @(posedge clk);
    start <= 1;
    entry = reader.get_entry();
$display("Entry point: %h", entry);
    start_pc <= entry;
    repeat (8) @(posedge clk);
    start <= 0;
end
    
initial begin
    #5us;
    $display("Watchdog timeout!");
    $finish;
end
endmodule