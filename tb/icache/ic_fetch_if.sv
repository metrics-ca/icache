// Fetch interface
interface ic_fetch_if(input clk, input rst_n);

logic [26:1]    fetch_addr;
logic           fetch_en;
logic           fetch_valid;
logic [31:0]    fetch_data;
logic           init_done;  // not part of transaction

endinterface;
