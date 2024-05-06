// Controller for instruction cache
import ic_pkg::*;

module ic_ctrl(
    // General
    input                   clk,
    input                   rst_n,

    // Fetch interface from CPU
    input [26:1]            fetch_addr,
    input                   fetch_en,
    output reg [1:0]        fetch_valid,
    output reg [31:0]       fetch_data,

    // Interface to DRAM controller
    output reg [26:4]       ic_mem_addr,
    output reg [1:0]        ic_mem_xid,
    output reg              ic_mem_re,
    input                   mem_ic_ready,
    input                   mem_ic_valid,
    input [1:0]             mem_ic_xid,
    input [127:0]           mem_ic_data,

    // Interface to data RAM 
    output reg              we_data, re_data,
    output ic_way_t         wr_way, rd_way,
    output ic_line_t        wr_line, rd_line,
    output ic_waddr_t       rd_word_even, rd_word_odd,
    output ic_fill_t        wr_data_even,
    input [15:0]            rd_data_even,
    output ic_fill_t        wr_data_odd,
    input [15:0]            rd_data_odd,
    
    // Interface to tag RAM 
    output reg [WAYS-1:0]   we_tag,
    output [WAYS-1:0]       re_tag,
    output ic_line_t        waddr_tag, raddr_tag,
    output ic_tag_entry_t   wdata_tag[WAYS],
    input ic_tag_entry_t    rdata_tag[WAYS],

    // Interface to LRU RAM 
    output reg              we_lru,
    output reg              re_lru,
    output ic_line_t        waddr_lru, raddr_lru,
    output ic_lru_t         wdata_lru,
    input ic_lru_t          rdata_lru
);

// Initialization
reg [LG_LINES:0]    init_cnt;
wire                init_done = init_cnt[LG_LINES];

always @(posedge clk)
    if (!rst_n)
        init_cnt <= 0;
    else if (!init_done)
        init_cnt <= init_cnt + 1;


// Requested address is either 0 or 2 mod 4, due to compressed instructions.
// We must be able to read 32 bits from either alignment.
// To this end, we split the data ram into two banks "even" and "odd" based
// on fetch_addr[1].  Any given 32-bit read will hit both banks.
// We must then reassemble the data properly.
// It is possible for a read from address 0xE mod 16 to "straddle".
// We will return the first 16 bits in this case; CPU must issue another
// fetch for the remainder.
// Since Gowin block RAMs are 16Kb each, we want to make them as tall
// as possible.  To this end, all address bits (line,way,word) are
// data RAM address bits.  To compute the correct data RAM address
// we must perform the tag access and way determination on the previous cycle.

ic_waddr_t fetch_word, fetch_word_p1, fetch_word_even, fetch_word_odd;
wire ic_line_t  fetch_line;
wire ic_tag_t   fetch_tag;

assign { fetch_tag,fetch_line,fetch_word} = fetch_addr[26:2];
assign fetch_word_p1 = fetch_word + fetch_addr[1];

always_comb begin
    if (fetch_addr[1]) begin
        fetch_word_odd = fetch_word;
        fetch_word_even = fetch_word_p1;
    end else begin
        fetch_word_even = fetch_word;
        fetch_word_odd = fetch_word_p1;
    end
end

wire   straddle = &fetch_word;
assign re_tag = {WAYS{fetch_en & init_done}};
assign raddr_tag = fetch_line;

// Tag compare
reg             tag_cmp_en_q1;
reg             straddle_q1;
reg             req_odd_q1;
ic_tag_t        fetch_tag_q1;
ic_line_t       fetch_line_q1;
ic_waddr_t      fetch_word_even_q1, fetch_word_odd_q1;

always @(posedge clk)
    if (!rst_n) begin
        tag_cmp_en_q1 <= 0;
        fetch_tag_q1 <= 0;
        fetch_line_q1 <= 0;
        fetch_word_even_q1 <= 0;
        fetch_word_odd_q1 <= 0;
        straddle_q1 <= 0;
        req_odd_q1 <= 0;
    end else begin
        tag_cmp_en_q1 <= fetch_en & init_done;
        fetch_tag_q1 <= fetch_tag;
        fetch_line_q1 <= fetch_line;
        fetch_word_even_q1 <= fetch_word_even;
        fetch_word_odd_q1 <= fetch_word_odd;
        straddle_q1 <= straddle;
        req_odd_q1 <= fetch_addr[1];
    end

reg [WAYS-1:0] tag_hit;

always_comb begin
    foreach (rdata_tag[i])
        tag_hit[i] = tag_cmp_en_q1 & rdata_tag[i].valid & (rdata_tag[i].tag == fetch_tag_q1);
end

// XXX: could try to do this more generically
wire [1:0]      tag_sel = {|tag_hit[3:2],tag_hit[3]|tag_hit[1]};
wire            miss = ~|tag_hit & tag_cmp_en_q1;
wire [26:4]     miss_addr = {fetch_tag_q1,fetch_line_q1};

reg             nxt_tag_wb_en;
ic_line_t       nxt_tag_wb_line;
ic_way_t        nxt_tag_wb_way;
ic_tag_entry_t  nxt_tag_wb_data;
reg [127:0]     mem_ic_data_q1;

reg             tag_wb_en;
ic_line_t       tag_wb_line;
ic_way_t        tag_wb_way;
ic_tag_entry_t  tag_wb_data;

// Writes to tag RAM
always_comb begin
    if (!init_done) begin
        // Initialization data
        we_tag = {WAYS{1'b1}};
        waddr_tag = init_cnt[LG_LINES-1:0];
        wdata_tag = '{ default:0};
    end else begin
        // Mission mode
        we_tag = tag_wb_en ? (1 << tag_wb_way) : 0;
        waddr_tag = tag_wb_line;
        wdata_tag = '{4{tag_wb_data}};
    end
end

// Data RAM interface
assign re_data = |tag_hit;
assign rd_way = tag_sel;
assign rd_line = fetch_line_q1;
assign rd_word_even = fetch_word_even_q1;
assign rd_word_odd = fetch_word_odd_q1;

logic       re_data_q;

// Final instruction assembly
always @(posedge clk) begin
    if (!rst_n) begin
        fetch_data <= 0;
        fetch_valid <= 0;
        re_data_q <= 0;
    end else begin
        fetch_valid[0] <= re_data_q;
        fetch_valid[1] <= re_data_q & ~straddle_q1;
        re_data_q <= re_data;
        if (req_odd_q1)
            fetch_data <= {rd_data_even,rd_data_odd};
        else
            fetch_data <= {rd_data_odd,rd_data_even};
    end
end

// Reads from LRU RAM
reg     lru_rd_update_en, lru_rd_update_en_q1;
reg     lru_wb_update_en, lru_wb_update_en_q1;

always_comb begin
    // XXX: LRU updates due to data writeback from DRAM take priority.
    // Otherwise you could churn a single way.
    if (mem_ic_valid) begin
        re_lru = 1'b1;
        raddr_lru = nxt_tag_wb_line;
        lru_rd_update_en = 0;
        lru_wb_update_en = 1;
    end else if (fetch_en & init_done) begin
        // Update due to data fetch
        re_lru = 1'b1;
        raddr_lru = fetch_line;
        lru_rd_update_en = 1;
        lru_wb_update_en = 0;
    end else begin
        re_lru = 0;
        raddr_lru = 'x;
        lru_rd_update_en = 0;
        lru_wb_update_en = 0;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        lru_rd_update_en_q1 <= 0;
        lru_wb_update_en_q1 <= 0;
    end else begin
        lru_rd_update_en_q1 <= lru_rd_update_en;
        lru_wb_update_en_q1 <= lru_wb_update_en;
    end
end

// Work out updated LRU data for fetch hit
// Move hit way to position 0 (rightmost)
ic_lru_t    lru_rd_update;

always_comb begin
    lru_rd_update = 'x;
    if (!miss) begin
        if (tag_sel == rdata_lru[3]) lru_rd_update = '{rdata_lru[2],rdata_lru[1],rdata_lru[0],tag_sel};
        else if (tag_sel == rdata_lru[2]) lru_rd_update = '{rdata_lru[3],rdata_lru[1],rdata_lru[0],tag_sel};
        else if (tag_sel == rdata_lru[1]) lru_rd_update = '{rdata_lru[3],rdata_lru[2],rdata_lru[0],tag_sel};
        else if (tag_sel == rdata_lru[0]) lru_rd_update = '{rdata_lru[3],rdata_lru[2],rdata_lru[1],tag_sel};
    end
end

// Work out updated LRU data for writeback
ic_lru_t    lru_wb_update;

assign lru_wb_update = '{rdata_lru[2],rdata_lru[1],rdata_lru[0],rdata_lru[3]};
assign tag_wb_way = rdata_lru[3];
    
localparam ic_lru_t LRU_INIT = '{ 3,2,1,0};

// Writes to LRU RAM
always_comb begin
    if (!init_done) begin
        // Initialization data
        we_lru = 1'b1;
        waddr_lru = init_cnt[LG_LINES-1:0];
        wdata_lru = LRU_INIT;
    end else if (lru_wb_update_en_q1) begin
        we_lru = 1;
        waddr_lru = tag_wb_line;
        wdata_lru = lru_wb_update;
    end else if (lru_rd_update_en_q1 & !miss) begin
        // Mission mode
        we_lru = 1;
        waddr_lru = fetch_line_q1;
        wdata_lru = lru_rd_update;
    end else begin
        we_lru = 0;
        waddr_lru = 'x;
        wdata_lru = 'x;
    end
end

// Memory controller interface
localparam N_MTX = 4;

reg [N_MTX-1:0] mx_valid;
reg [26:4]      mx_addr[N_MTX];
reg [N_MTX-1:0] mx_issued;
reg [N_MTX-1:0] mx_rcvd;

// Determine if miss is actionable
reg             mx_new;

always_comb begin
    mx_new = miss;
    foreach (mx_valid[i])
        if (mx_valid[i] && mx_addr[i] == miss_addr) mx_new = 0;
end

// Find a free slot for new transaction
reg [N_MTX-1:0] free_slot;

always_comb begin
    free_slot = 0;
    if (mx_new) begin
        foreach (mx_valid[i]) 
            if (!mx_valid[i] & ~|free_slot)
                free_slot[i] = 1'b1;
    end
end

// Issue new work
reg [26:4]      next_mem_addr;
reg [1:0]       next_mem_xid;
reg             next_mem_re;

always_comb begin
    next_mem_re = 0;
    next_mem_addr = 0;
    next_mem_xid = 0;
    foreach (mx_issued[i])
        if (mx_valid[i]) 
            if (!next_mem_re && !mx_issued[i]) begin
                next_mem_re = 1;
                next_mem_xid = i[1:0];
                next_mem_addr = mx_addr[i];
            end
end

always @(posedge clk) begin
    if (!rst_n) begin
        ic_mem_addr <= 0;
        ic_mem_xid <= 0;
        ic_mem_re <= 0;
    end else begin
        ic_mem_addr <= next_mem_addr;
        ic_mem_xid <= next_mem_xid;
        ic_mem_re <= next_mem_re;
    end
end

// Update valid bits 
always @(posedge clk) begin
    if (!rst_n)
        mx_valid <= 0;
    else begin
        foreach (mx_valid[i]) begin
            if (mx_new && free_slot[i])
                mx_valid[i] <= 1'b1;
            else if (mem_ic_valid && i == mem_ic_xid)
                mx_valid[i] <= 1'b0;
        end
    end
end

// Update address
always @(posedge clk) begin
    if (!rst_n)
        foreach (mx_addr[i]) mx_addr[i] <= 0;
    else begin
        foreach (mx_addr[i])
            if (mx_new && free_slot[i])
                mx_addr[i] <= miss_addr;
    end
end

// Update mx_issued
always @(posedge clk) begin
    if (!rst_n)
        foreach (mx_issued[i]) mx_issued[i] <= 0;
    else begin
        foreach (mx_issued[i])
            if (free_slot[i])
                mx_issued[i] <= 0;
            else if (mem_ic_ready && next_mem_re && !mx_issued[i])
                mx_issued[i] <= 1;
            else if (mem_ic_valid && i == mem_ic_xid)
                mx_issued[i] <= 1'b0;
    end
end

// Tag, data writeback.
// To avoid any races between tag-data reads and writes, we write
// the data one clock cycle after we write the tag.  This parallels how
// we read the tag, then read the data a clock later.
// Both the tag and data memories are write-through (if you read and write 
// the same address, the read data will be the write data) so an access
// concurrent to the writeback will see the new data.  An access a clock earlier
// will see old data.

// All tag/data writeback accesses must be delayed one cycle after mem_ic_valid
// to allow read of the LRU.

wire [26:4] tag_wb_addr = mx_addr[mem_ic_xid];

assign nxt_tag_wb_en = mem_ic_valid;
assign nxt_tag_wb_line = tag_wb_addr[4+:LG_LINES];
assign nxt_tag_wb_data = '{1'b1,tag_wb_addr[4+LG_LINES+:TAG_BITS]};
            
always @(posedge clk) begin
    tag_wb_en <= nxt_tag_wb_en;
    tag_wb_line <= nxt_tag_wb_line;
    tag_wb_data <= nxt_tag_wb_data;
    mem_ic_data_q1 <= mem_ic_data;

    we_data <= tag_wb_en;
    wr_way <= tag_wb_way;
    wr_line <= tag_wb_line;
    foreach (wr_data_even[i]) begin
        wr_data_even[i] <= mem_ic_data_q1[i*32+:16];
        wr_data_odd[i] <= mem_ic_data_q1[i*32+16+:16];
    end
end
    
        
endmodule