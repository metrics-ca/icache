module ic_syn_top(
    // General
    input                   clk,
    input                   rst_n,

    // Fetch interface from CPU
    input [26:1]            fetch_addr,
    input                   fetch_en,
    output                  fetch_valid,
    output [31:0]           fetch_data,

    // Interface to memory controller
    output [26:4]           ic_mem_addr,
    output [1:0]            ic_mem_xid,
    output                  ic_mem_re,
    input                   mem_ic_ready,
    input                   mem_ic_valid,
    input [1:0]             mem_ic_xid,
    input [31:0]            mem_ic_data2
);

import ic_pkg::*;

reg [127:0]     mem_ic_data;

ic_top real_dut(.*);

always @(posedge clk)
    if (!rst_n)
        mem_ic_data <= 128'd1;
    else
        mem_ic_data <= {mem_ic_data[126:0],1'b0} ^ mem_ic_data[127] ^ mem_ic_data[125] ^ mem_ic_data[0] ^ mem_ic_data2;

endmodule