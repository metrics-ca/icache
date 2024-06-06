// A behavioral model of the Gowin DDR3 memory controller IP+DRAM.
// Hopefully correct, as the real thing is difficult to simulate.
// and the controller is not well documented.
import elf_pkg::*;

module gowin_ddr_model(
    input logic         clk,
    input logic         rst_n,

    input logic [2:0]   ddr_cmd,
    input logic         ddr_cmd_en,
    input logic [27:0]  ddr_addr,
    input logic [127:0] ddr_wr_data,
    input logic [15:0]  ddr_wr_data_mask,
    input logic         ddr_wr_data_en,
    
    output logic        ddr_calib_done,
    output logic        ddr_cmd_ready,
    output logic [127:0] ddr_rd_data,
    output logic        ddr_rd_data_valid
);

logic [127:0]   dram[int];  // indexed by ddr_addr[26:4]

class ElfIf extends ElfMemory;
    virtual function void   write(u64 addr, bit [7:0] data[]);
        foreach (data[i]) begin
            int cur = addr + i;
            int row = cur[26:4];
            int col = cur[3:0];
            dram[row][col*8+:8] = data[i];
$display("write row %d byte %d = %h", row, col, data[i]);
        end
    endfunction
endclass
    
ElfIf elf_if = new;

typedef struct {
    logic [26:4]    addr;
    logic [127:0]   data;
    int             cycle;  // on which req received 
} req_t;

req_t           reqs[$];
int             cycle, row;
int             latency = 3;

always @(posedge clk)
    if (!rst_n) begin
        ddr_calib_done <= 0;
        ddr_cmd_ready <= 0;
        ddr_rd_data_valid <= 0;
    end else begin
        // Command phase
        cycle <= cycle + 1;
        ddr_calib_done <= (cycle > 100);
        ddr_cmd_ready <= (reqs.size() < 4) & ddr_calib_done;
        if (ddr_cmd_ready & ddr_cmd_en) begin
            row = ddr_addr[26:4];
            prepare_row(row);
            if (ddr_cmd == 3'b001) begin
                // read - queue transaction
                reqs.push_back('{row,dram[row],cycle});
            end else if (ddr_cmd === 3'b000) begin
                // write - do immediately
                if (ddr_wr_data_en)
                    foreach (ddr_wr_data_mask[i])
                        dram[row][i*8+:8] = ddr_wr_data[i*i+:8];
                else
                    $display("@%0t: %m: ddr_wr_data_en not asserted for write", $time);
            end else begin
                $display("@%0t: %m: invalid command %b", $time, ddr_cmd);
            end
        end

        // Read phase
        if (reqs.size() > 0 && reqs[0].cycle + latency <= cycle) begin
            ddr_rd_data <= reqs[0].data;
            ddr_rd_data_valid <= 1;
            void'(reqs.pop_front());
        end else begin
            ddr_rd_data <= 'x;
            ddr_rd_data_valid <= 0;
        end
    end

task prepare_row(int row);
    if (!dram.exists(row)) begin
        for (int i = 0; i < 4; i++)
            dram[row][i*32+:32] = (row * 5734854307) ^ (i * 9820842149);
    end
endtask
endmodule