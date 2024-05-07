// DRAM arbiter:
// Arbitrate amongst the major memory transaction initiators.
module dram_arb(
    input logic     clk,
    input logic     rst_n,

    // Instruction cache (initiator 0)
    input logic [26:4]  ic_mem_addr,
    input logic [1:0]   ic_mem_xid,
    input logic         ic_mem_re,
    output logic        mem_ic_ready,
    output logic        mem_ic_valid,
    
    // Common to all initiators
    output logic [1:0]  mem_xxx_xid,
    output logic [127:0] mem_xxx_data,

    // Gowin DDR interface
    input logic         ddr_calib_done,
    output logic [2:0]  ddr_cmd,
    output logic        ddr_cmd_en,
    output logic [27:0] ddr_addr,
    output logic [127:0] ddr_wr_data,
    output logic [15:0] ddr_wr_data_mask,
    output logic        ddr_wr_data_en,
    input logic         ddr_cmd_ready,
    input logic [127:0] ddr_rd_data,
    input logic         ddr_rd_data_valid
);

// FIFO: each read transaction has {initiator,xid} which is returned when read completes.
localparam LG_INIT = 2;     // 4 initiators
localparam LG_XID = 2;      // 4 XIDs per 
localparam LG_DEPTH = 4;    // 16 slots in FIFO (for Gowin SSRAM)

logic [LG_DEPTH-1:0]    wr_ptr, rd_ptr;
logic [LG_INIT+LG_XID-1:0] fifo[1<<LG_DEPTH];
logic                   push, pop, empty, full;
logic [LG_INIT-1:0]     wr_init, rd_init;
logic [LG_XID-1:0]      wr_xid;

wire                    eff_push = push & ~full;
wire                    eff_pop = pop & ~empty;

wire [LG_DEPTH-1:0]     next_wr_ptr = wr_ptr + 1;
wire [LG_DEPTH-1:0]     next_rd_ptr = rd_ptr + 1;

always @(posedge clk)
    if (~rst_n) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        empty <= 1;
        full <= 0;
    end else begin
        if (eff_push) begin
            fifo[wr_ptr] <= {wr_init,wr_xid};
            wr_ptr <= next_wr_ptr;
        end
        if (eff_pop) begin
            rd_ptr <= next_rd_ptr;
        end
        if (eff_push) begin
            if (eff_pop) begin
                // If both asserted, then we were neither empty nor full,
                // and that will continue to be the case.
            end else begin
                // Push and no pop.  Never empty.  Full if pointers are made equal.
                empty <= 0;
                full <= (next_wr_ptr == rd_ptr);
            end
        end else begin
            if (eff_pop) begin
                // Pop and no push.  Never full.  Empty if pointers are made equal.
                full <= 0;
                empty <= (next_rd_ptr == wr_ptr);
            end else begin
                // No action - no change
            end
        end
    end

assign {rd_init,mem_xxx_xid} = fifo[rd_ptr];
assign mem_ic_valid = (rd_init == 2'b00) & !empty & ddr_rd_data_valid;
assign mem_xxx_data = ddr_rd_data;

// eventually, an arbiter
assign ddr_cmd_en = ic_mem_re;
assign ddr_cmd = 3'b001; // read 
assign ddr_addr = {1'b0,ic_mem_addr,4'b0};
assign ddr_wr_data = 128'b0;
assign ddr_wr_data_mask = 16'b0;
assign ddr_wr_data_en = 0;

assign mem_ic_ready = ~full;
assign push = ic_mem_re & ddr_cmd_ready;
assign pop = ddr_rd_data_valid;

assign wr_init = 0;
assign wr_xid = ic_mem_xid;

endmodule

