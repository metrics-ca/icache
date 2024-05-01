import ic_pkg::*;

module ic_lru_ram(
    input               clk,
    input               rst_n,

    // Read interface
    input ic_line_t     rd_line,
    input               rd_en,
    output ic_lru_t     rd_data,

    // Write interface
    input ic_lru_t      wr_data,
    input ic_line_t     wr_line,
    input               wr_en
);

case (IMPL)
BEHAVIORAL: begin

ic_lru_t        l_ram[LINES];

always @(posedge clk)
    if (rst_n) begin
        if (wr_en)
            l_ram[wr_line] <= wr_data;
        if (rd_en)
            rd_data <= l_ram[rd_line];
    end

end
GOWIN: begin

wire [7:0] wr_tap = wr_data;
wire [7:0] rd_tap = rd_data;
wire coll = (rd_line == wr_line) && rd_en && wr_en;
reg coll_q;
ic_lru_t  wt_data, int_rd_data;

always @(posedge clk)
    if (!rst_n)
        coll_q <= 0;
    else
        coll_q <= coll;

    // Write port: 256 x 8
    // Read port: 256 x 8
    DPB #(
        .READ_MODE0(0),     // No pipeline
        .READ_MODE1(0),     // No pipeline
        .WRITE_MODE0(1),    // Write-through
        .WRITE_MODE1(1),    // Write-through
        .BIT_WIDTH_0(8),    // Write port width
        .BIT_WIDTH_1(8),    // Read port width
        .BLK_SEL_0(0),      // No need for extra row decode
        .BLK_SEL_1(0),      // No need for extra row decode
        .RESET_MODE("SYNC")
    ) u_bram(
        // write port
        .CLKA(clk),
        .CEA(1'b1),
        .WREA(wr_en),
        .RESETA(~rst_n),
        .BLKSELA(3'b0),
        .OCEA(1'b0),
        .ADA({3'b000,wr_line,3'b000}),
        .DIA({8'b0,wr_data}),
        .DOA(wt_data),

        // read port
        .CLKB(clk),
        .CEB(rd_en & !coll),
        .WREB(1'b0),
        .RESETB(~rst_n),
        .BLKSELB(3'b0),
        .OCEB(1'b0),
        .ADB({3'b000,rd_line,3'b000}),
        .DIB('0),
        .DOB(int_rd_data)
    );

assign rd_data = coll_q ? wt_data : int_rd_data;

end
default: begin
    $error("Must select implementation for ic_data_ram");
end
endcase
endmodule

