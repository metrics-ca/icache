module ic_ctrl_cover(
        input       clk,
        input       rst_n,
        input       re_lru,
        input       we_lru,
        input [7:0] rdata_lru,
        input [1:0] tag_sel,
        input [7:0] lru_rd_update,
        input [7:0] lru_wb_update,
        input       do_lru_rd_update,
        input       do_lru_wb_update,
        input       init_done,
        input [7:0] raddr_lru,
        input [7:0] waddr_lru
);

covergroup cg_lru @(posedge clk iff rst_n);
    option.per_instance = 1;

    coll: coverpoint (raddr_lru == waddr_lru && we_lru && re_lru);

    all_rd: coverpoint lru_rd_update iff (init_done && do_lru_rd_update && !do_lru_wb_update) {
        bins b0123 = { 8'b00_01_10_11 };
        bins b0132 = { 8'b00_01_11_10 };
        bins b0213 = { 8'b00_10_01_11 };
        bins b0231 = { 8'b00_10_11_01 };
        bins b0312 = { 8'b00_11_01_10 };
        bins b0321 = { 8'b00_11_10_01 };
        bins b1023 = { 8'b01_00_10_11 };
        bins b1032 = { 8'b01_00_11_10 };
        bins b1203 = { 8'b01_10_00_11 };
        bins b1230 = { 8'b01_10_11_00 };
        bins b1302 = { 8'b01_11_00_10 };
        bins b1320 = { 8'b01_11_10_00 };
        bins b2013 = { 8'b10_00_01_11 };
        bins b2031 = { 8'b10_00_11_01 };
        bins b2103 = { 8'b10_01_00_11 };
        bins b2130 = { 8'b10_01_11_00 };
        bins b2301 = { 8'b10_11_00_01 };
        bins b2310 = { 8'b10_11_01_00 };
        bins b3012 = { 8'b11_00_01_10 };
        bins b3021 = { 8'b11_00_10_01 };
        bins b3102 = { 8'b11_01_00_10 };
        bins b3120 = { 8'b11_01_10_00 };
        bins b3201 = { 8'b11_10_00_01 };
        bins b3210 = { 8'b11_10_01_00 };
        illegal_bins other = default;
    }

    all_wb: coverpoint lru_wb_update iff (init_done && do_lru_wb_update) {
        bins b0123 = { 8'b00_01_10_11 };
        bins b0132 = { 8'b00_01_11_10 };
        bins b0213 = { 8'b00_10_01_11 };
        bins b0231 = { 8'b00_10_11_01 };
        bins b0312 = { 8'b00_11_01_10 };
        bins b0321 = { 8'b00_11_10_01 };
        bins b1023 = { 8'b01_00_10_11 };
        bins b1032 = { 8'b01_00_11_10 };
        bins b1203 = { 8'b01_10_00_11 };
        bins b1230 = { 8'b01_10_11_00 };
        bins b1302 = { 8'b01_11_00_10 };
        bins b1320 = { 8'b01_11_10_00 };
        bins b2013 = { 8'b10_00_01_11 };
        bins b2031 = { 8'b10_00_11_01 };
        bins b2103 = { 8'b10_01_00_11 };
        bins b2130 = { 8'b10_01_11_00 };
        bins b2301 = { 8'b10_11_00_01 };
        bins b2310 = { 8'b10_11_01_00 };
        bins b3012 = { 8'b11_00_01_10 };
        bins b3021 = { 8'b11_00_10_01 };
        bins b3102 = { 8'b11_01_00_10 };
        bins b3120 = { 8'b11_01_10_00 };
        bins b3201 = { 8'b11_10_00_01 };
        bins b3210 = { 8'b11_10_01_00 };
        illegal_bins other = default;
    }

    all: coverpoint rdata_lru iff (init_done && (do_lru_rd_update || do_lru_wb_update)) {
        bins b0123 = { 8'b00_01_10_11 };
        bins b0132 = { 8'b00_01_11_10 };
        bins b0213 = { 8'b00_10_01_11 };
        bins b0231 = { 8'b00_10_11_01 };
        bins b0312 = { 8'b00_11_01_10 };
        bins b0321 = { 8'b00_11_10_01 };
        bins b1023 = { 8'b01_00_10_11 };
        bins b1032 = { 8'b01_00_11_10 };
        bins b1203 = { 8'b01_10_00_11 };
        bins b1230 = { 8'b01_10_11_00 };
        bins b1302 = { 8'b01_11_00_10 };
        bins b1320 = { 8'b01_11_10_00 };
        bins b2013 = { 8'b10_00_01_11 };
        bins b2031 = { 8'b10_00_11_01 };
        bins b2103 = { 8'b10_01_00_11 };
        bins b2130 = { 8'b10_01_11_00 };
        bins b2301 = { 8'b10_11_00_01 };
        bins b2310 = { 8'b10_11_01_00 };
        bins b3012 = { 8'b11_00_01_10 };
        bins b3021 = { 8'b11_00_10_01 };
        bins b3102 = { 8'b11_01_00_10 };
        bins b3120 = { 8'b11_01_10_00 };
        bins b3201 = { 8'b11_10_00_01 };
        bins b3210 = { 8'b11_10_01_00 };
        illegal_bins other = default;
    }

endgroup

cg_lru inst = new;

endmodule