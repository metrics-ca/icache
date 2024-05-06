class dram_ctrl_monitor extends uvm_monitor;
    `uvm_component_utils(dram_ctrl_monitor);

    virtual dram_ctrl_if    vif;
    dram_ctrl_xact          item, read_q[$];
    uvm_analysis_port#(dram_ctrl_xact) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        assert(uvm_config_db#(virtual dram_ctrl_if)::get(this, "", "vif", vif));
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            forever @(posedge vif.clk) begin
                if (vif.ddr_cmd_en) begin
                    item = dram_ctrl_xact::type_id::create("item");
                    item.cmd = vif.ddr_cmd;
                    item.addr = vif.ddr_addr;
                    if (vif.ddr_cmd == 3'b001) begin
                        // Read - need to wait for data
                        read_q.push_back(item);
                    end else begin
                        // Hopefully write
                        item.data = vif.ddr_wr_data;
                        item.mask = vif.ddr_wr_data_mask;
                        ap.write(item);
                    end
                end
                if (vif.ddr_rd_data_valid) begin
                    item = read_q.pop_front();
                    if (item) begin
                        item.data = vif.ddr_rd_data;
                        item.mask = 16'hFFFF;
                        ap.write(item);
                    end else begin
                        `uvm_error(get_type_name(), "Received read data for unknown previous transaction.");
                    end
                end
            end
        join_none
    endtask
endclass

                    


