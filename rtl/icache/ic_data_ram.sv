import ic_pkg::*;

module ic_data_ram(
    input               clk,
    input               rst_n,

    // Read interface
    input ic_way_t      rd_way,
    input ic_line_t     rd_line,
    input ic_waddr_t    rd_word,
    input               rd_en,
    output reg [15:0]   rd_data,

    // Fill interface
    input ic_fill_t     wr_data,
    input ic_way_t      wr_way,
    input ic_line_t     wr_line,
    input               wr_en
);

// Common logic: read/write collision.
// Most embedded RAMs don't support read+write to the same address in the same clock.
// If this happens, we want the write data to be forwarded to the reader.
wire coll = (rd_line == wr_line) && rd_en && wr_en;
reg coll_q;

ic_fill_t  wt_data;
reg [15:0] int_rd_data;
ic_waddr_t rd_word_q;

always @(posedge clk)
    if (!rst_n) begin
        coll_q <= 0;
        rd_word_q <= 0;
    end else begin
        coll_q <= coll;
        rd_word_q <= rd_word;
    end

assign rd_data = coll_q ? wt_data[rd_word_q] : int_rd_data;

case (IMPL)
BEHAVIORAL: begin

// Data corruption widget:
localparam FAIL_PCT = 100;
logic [63:0]            syndrome = '0;
bit [5:0]               bad_bit;
bit [7:0]               bad_line;
wire [63:0]             eff_syndrome = (rd_line == bad_line) ? syndrome : '0;

initial begin
    if ($urandom_range(0, 99) < FAIL_PCT) begin
        bad_bit = $urandom;
        bad_line = $urandom;
        syndrome[bad_bit] = 1;
    end
end

ic_fill_t               d_ram[WAYS * LINES];

always @(posedge clk)
    if (!rst_n)
        wt_data <= '0;
    else begin
        wt_data <= wr_data;
        if (wr_en)
            d_ram[{wr_line,wr_way}] <= wr_data ^ eff_syndrome;
        if (rd_en)
            int_rd_data <= d_ram[{rd_line,rd_way}][rd_word];
    end

end
GOWIN: begin

    // Write port: 1K x 64
    // Read port: 4K x 16
    for (genvar i = 0; i < 4; i++) begin: RAMs
        DPB #(
            .READ_MODE0(0),     // No pipeline
            .READ_MODE1(0),     // No pipeline
            .WRITE_MODE0(1),    // Write-through
            .WRITE_MODE1(1),    // Write-through
            .BIT_WIDTH_0(16),   // Write port width
            .BIT_WIDTH_1(4),    // Read port width
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
            .ADA({wr_line,wr_way,4'b0011}),
            .DIA({wr_data[3][i*4+:4],wr_data[2][i*4+:4],wr_data[1][i*4+:4],wr_data[0][i*4+:4]}),
            .DOA({wt_data[3][i*4+:4],wt_data[2][i*4+:4],wt_data[1][i*4+:4],wt_data[0][i*4+:4]}),

            // read port
            .CLKB(clk),
            .CEB(rd_en & !coll),
            .WREB(1'b0),
            .RESETB(~rst_n),
            .BLKSELB(3'b0),
            .OCEB(1'b0),
            .ADB({rd_line,rd_way,rd_word,2'b0}),
            .DIB('0),
            .DOB(int_rd_data[i*4+:4])
        );
    end

end
default: begin
    $error("Must select implementation for ic_data_ram");
end
endcase
endmodule