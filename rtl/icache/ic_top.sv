// Top-level model for instruction cache
module ic_top(
    // General
    input                   clk,
    input                   rst_n,

    // Fetch interface from CPU
    input [26:1]            fetch_addr,
    input                   fetch_en,
    output [1:0]            fetch_valid,
    output [31:0]           fetch_data,

    // Interface to memory controller
    output [26:4]           ic_mem_addr,
    output [1:0]            ic_mem_xid,
    output                  ic_mem_re,
    input                   mem_ic_ready,
    input                   mem_ic_valid,
    input [1:0]             mem_ic_xid,
    input [127:0]           mem_ic_data
);

import ic_pkg::*;

wire                rst_p = ~rst_n;

// Data memory:
// Data memory is implemented as two memories: one for "even" words and one for "odd" words.
// A compact instruction requires data from one memory; a 32-bit instruction requires data from both.
// Address is combination of offset within line, and line.
wire                    we_data, re_data;
wire ic_way_t           wr_way, rd_way;
wire ic_line_t          wr_line, rd_line;
wire ic_waddr_t         rd_word_even, rd_word_odd;
wire ic_fill_t          wr_data_even, wr_data_odd;
wire [15:0]             rd_data_even, rd_data_odd;

ic_data_ram u_data_even(
    .clk(clk),
    .rst_n(rst_n),
    .rd_way(rd_way),
    .rd_line(rd_line),
    .rd_word(rd_word_even),
    .rd_en(re_data),
    .rd_data(rd_data_even),
    .wr_data(wr_data_even),
    .wr_way(wr_way),
    .wr_line(wr_line),
    .wr_en(we_data)
);

ic_data_ram u_data_odd(
    .clk(clk),
    .rst_n(rst_n),
    .rd_way(rd_way),
    .rd_line(rd_line),
    .rd_word(rd_word_odd),
    .rd_en(re_data),
    .rd_data(rd_data_odd),
    .wr_data(wr_data_odd),
    .wr_way(wr_way),
    .wr_line(wr_line),
    .wr_en(we_data)
);

// Tag memory:
// Each way has its own tag memory (since byte/word enables not supported.)
wire [WAYS-1:0]         we_tag, re_tag;
wire ic_line_t          waddr_tag, raddr_tag;
wire ic_tag_entry_t     wdata_tag[WAYS], rdata_tag[WAYS];

for (genvar i = 0; i < WAYS; i++) begin: TAG_RAMS
    ic_tag_ram u_tag(
        .clk(clk),
        .rst_n(rst_n),
        .rd_line(raddr_tag),
        .rd_en(re_tag[i]),
        .rd_data(rdata_tag[i]),
        .wr_data(wdata_tag[i]),
        .wr_line(waddr_tag),
        .wr_en(we_tag[i])
    );
end

// LRU: single 
wire                    we_lru, re_lru;
wire ic_line_t          waddr_lru, raddr_lru;
wire ic_lru_t           wdata_lru, rdata_lru;

ic_lru_ram u_lru(
    .clk(clk),
    .rst_n(rst_n),
    .rd_line(raddr_lru),
    .rd_en(re_lru),
    .rd_data(rdata_lru),
    .wr_data(wdata_lru),
    .wr_line(waddr_lru),
    .wr_en(we_lru)
);

// Controller
ic_ctrl u_ctrl(.*);

endmodule