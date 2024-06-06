module ic_decode(
    input               clk,
    input               rst_n,

    // Interface to controller
    output logic [26:1] fetch_addr_n1,
    output              fetch_en_n1,

    input [1:0]         fetch_valid_n3,
    
    // Direct from data memory
    input [15:0]        rd_data_even_n3,
    input [15:0]        rd_data_odd_n3,

    // Interface to scheduler
    input               sch_ic_go,      // controlled from stage 6
    input [26:1]        sch_ic_pc,      // controlled from stage 4

    // Interface to CPU core 
    // eventually: support for branching
    output logic [2:0]  ic_cpu_ctx_q3,
    output logic [26:1] ic_cpu_pc_q3,
    output logic [31:0] ic_cpu_insn_q3,
    output logic        ic_cpu_ctx_en_q3,
    
    // A/B inputs connect directly to register file RAM and are flopped there.
    // D inputs are used later in the pipeline so we flop them.
    output logic [4:0]  ic_cpu_ra_n3,    
    output logic        ic_cpu_ra_en_n3, 
    output logic [4:0]  ic_cpu_rb_n3,   
    output logic        ic_cpu_rb_en_n3,
    output logic [4:0]  ic_cpu_rd_q3,
    output logic        ic_cpu_rd_en_q3
);

localparam IC_GO_STAGE = 6; // generated in q6
localparam IC_PC_STAGE = 6;

logic [2:0]             ctx_q0;         // Context counter for initiation
logic [7:0]             active_q0;      // Which threads are running?

logic [26:1]            init_pc[8];     // PC for initiation
logic [15:0]            insn_lo[8];     // 16LSB of instruction for straddle case
logic [7:0]             straddle;       // Did previous round straddle?

wire [2:0]              go_ctx = ctx_q0 - IC_GO_STAGE;
wire [2:0]              pc_ctx = ctx_q0 - IC_PC_STAGE;

// active_q0/initiation context
always @(posedge clk)
    if (!rst_n) begin
        ctx_q0 <= 0;
        active_q0 <= 8'h00;
    end else begin
        ctx_q0 <= ctx_q0 + 1;
        active_q0[go_ctx] <= sch_ic_go;
    end

// Initiation PC
always @(posedge clk)
    if (!rst_n) begin
        init_pc <= '{ default: 0 };
    end else begin
        init_pc[pc_ctx] <= sch_ic_pc;
    end

assign fetch_addr_n1 = init_pc[ctx_q0];
assign fetch_en_n1 = active_q0[ctx_q0];

// Deswizzle read data
wire [2:0]              rd_ctx = ctx_q0 - 2; // q2 == n3
wire [26:1]             rd_pc = init_pc[rd_ctx];
logic [31:0]            insn;

always_comb
    if (straddle[rd_ctx])
        insn = {rd_data_even_n3,insn_lo[rd_ctx]};
    else if (init_pc[rd_ctx][1])
        insn = {rd_data_even_n3,rd_data_odd_n3};
    else
        insn = {rd_data_odd_n3,rd_data_even_n3};
        
// Save straddle state
always @(posedge clk)
    if (!rst_n) begin
        straddle <= 0;
    end else if (fetch_valid_n3 == 2'b01) begin
        straddle[rd_ctx] <= 1;
        insn_lo[rd_ctx] <= rd_data_odd_n3;
    end else begin
        straddle[rd_ctx] <= 0;
    end

// Determine register file usage
logic [4:0]             cpu_rd_n3;
logic                   cpu_rd_en_n3;

always_comb begin
    if (insn[1:0] == 2'b11) begin
        casex (insn[6:2])
        5'b00000,
        5'b011x0,
        5'b11001,
        5'b01101:  begin  cpu_rd_n3 = insn[11:7];        cpu_rd_en_n3 = 1; end
        default:   begin  cpu_rd_n3 = 'x;                cpu_rd_en_n3 = 0; end
        endcase
    end else begin
        casex ({insn[15:13],insn[1:0]})
        5'b0xx_00: begin  cpu_rd_n3 = {2'b01,insn[4:2]}; cpu_rd_en_n3 = 1; end
        5'b0xx_01,
        5'b0xx_10: begin  cpu_rd_n3 = insn[11:7];        cpu_rd_en_n3 = 1; end
        5'b100_01: begin  cpu_rd_n3 = {2'b01,insn[9:7]}; cpu_rd_en_n3 = 1; end
        5'b100_10:
            if (!insn[12] && !insn[6:2] ||
                 insn[12] && |insn[6:2])
                   begin  cpu_rd_n3 = insn[11:7];        cpu_rd_en_n3 = 1; end
        default:   begin  cpu_rd_n3 = 'x;                cpu_rd_en_n3 = 0; end
        endcase
    end
end

always_comb begin
    if (insn[1:0] == 2'b11) begin
        ic_cpu_ra_n3 = insn[19:15]; ic_cpu_ra_en_n3 = 1;
    end else begin
        casex ({insn[15:13],insn[1:0]})
        5'b000_00,
        5'b101_10,
        5'b11x_10: begin ic_cpu_ra_n3 = 2;                 ic_cpu_ra_en_n3 = 1; end
        5'bxx1_00,
        5'bx1x_00,
        5'b1xx_00,
        5'b11x_01: begin ic_cpu_ra_n3 = {2'b01,insn[9:7]}; ic_cpu_ra_en_n3 = 1; end
        5'b0xx_01,
        5'b100_01,
        5'b0xx_10,
        5'b100_10: begin ic_cpu_ra_n3 = insn[11:7];        ic_cpu_ra_en_n3 = 1; end
        default:   begin ic_cpu_ra_n3 = 'x;                ic_cpu_ra_en_n3 = 0; end
        endcase
    end
end

always_comb begin
    if (insn[1:0] == 2'b11) begin
        ic_cpu_rb_n3 = insn[24:20]; ic_cpu_rb_en_n3 = 1;
    end else begin
        casex ({insn[15:13],insn[1:0]})
        5'b1xx_00: begin ic_cpu_rb_n3 = {2'b01,insn[4:2]}; ic_cpu_rb_en_n3 = 1; end
        5'b100_01:
            if (insn[11:10] == 2'b11)
                   begin ic_cpu_rb_n3 = {2'b01,insn[4:2]}; ic_cpu_rb_en_n3 = 1; end
        5'b100_10,
        5'b1xx_10: begin ic_cpu_rb_n3 = insn[6:2];         ic_cpu_rb_en_n3 = 1; end
        default:   begin ic_cpu_rb_n3 = 'x;                ic_cpu_rb_en_n3 = 0; end
        endcase
    end
end 

    
// Final output
always @(posedge clk)
    if (!rst_n) begin
        ic_cpu_ctx_q3 <= 0;
        ic_cpu_pc_q3 <= 0;
        ic_cpu_insn_q3 <= 0;
        ic_cpu_ctx_en_q3 <= 0;
        ic_cpu_rd_q3 <= 0;
        ic_cpu_rd_en_q3 <= 0;
    end else begin
        ic_cpu_ctx_q3 <= rd_ctx;
        ic_cpu_pc_q3 <= rd_pc;
        ic_cpu_insn_q3 <= insn;
        ic_cpu_ctx_en_q3 <= fetch_valid_n3;
        ic_cpu_rd_q3 <= cpu_rd_n3;
        ic_cpu_rd_en_q3 <= cpu_rd_en_n3;
    end

endmodule