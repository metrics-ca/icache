interface dram_ctrl_if(input clk, input rst_n);

logic           ddr_calib_done;
logic [2:0]     ddr_cmd;
logic           ddr_cmd_en;
logic [27:0]    ddr_addr;
logic [127:0]   ddr_wr_data;
logic [15:0]    ddr_wr_data_mask;
logic           ddr_wr_data_en;
logic           ddr_cmd_ready;
logic [127:0]   ddr_rd_data;
logic           ddr_rd_data_valid;
    
endinterface