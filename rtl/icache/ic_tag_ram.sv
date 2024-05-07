import ic_pkg::*;

module ic_tag_ram(
    input               clk,
    input               rst_n,

    // Read interface (2 ports)
    input ic_line_t     rd_line,
    input               rd_en,
    output ic_tag_entry_t rd_data,

    // Write interface
    input ic_tag_entry_t wr_data,
    input ic_line_t     wr_line,
    input               wr_en
);

// Common logic: read/write collision.
// Most embedded RAMs don't support read+write to the same address in the same clock.
// If this happens, we want the write data to be forwarded to the reader.
wire coll = (rd_line == wr_line) && rd_en && wr_en;
reg coll_q;
ic_tag_entry_t  wt_data, int_rd_data;

assign rd_data = coll_q ? wt_data : int_rd_data;

case (IMPL)
BEHAVIORAL: begin

ic_tag_entry_t  t_ram[LINES];

always @(posedge clk)
    if (!rst_n) begin
        coll_q <= 0;
        wt_data <= '0;
    end else begin
        coll_q <= coll;
        wt_data <= wr_data;
        if (wr_en)
            t_ram[wr_line] <= wr_data;
        if (rd_en)
            int_rd_data <= t_ram[rd_line];
    end

end
GOWIN: begin

    // Write port: 256 x 16
    // Read port: 256 x 16
    DPB #(
        .READ_MODE0(0),     // No pipeline
        .READ_MODE1(0),     // No pipeline
        .WRITE_MODE0(1),    // Write-through
        .WRITE_MODE1(1),    // Write-through
        .BIT_WIDTH_0(16),   // Write port width
        .BIT_WIDTH_1(16),   // Read port width
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
        // Undocumented: simulation model implies that bottom two address bits are byte enables!
        .ADA({2'b00,wr_line,4'b0011}),
        .DIA(wr_data),
        .DOA(wt_data),

        // read port
        .CLKB(clk),
        .CEB(rd_en & !coll),
        .WREB(1'b0),
        .RESETB(~rst_n),
        .BLKSELB(3'b0),
        .OCEB(1'b0),
        .ADB({2'b00,rd_line,4'b0000}),
        .DIB('0),
        .DOB(int_rd_data)
    );

end
default: begin
    $error("Must select implementation for ic_data_ram");
end
endcase
endmodule
