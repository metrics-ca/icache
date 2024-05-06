class ic_driver extends uvm_driver#(ic_xact);
    `uvm_component_utils(ic_driver)

    uvm_seq_item_pull_port#(ic_xact, ic_xact) seq_item_ports[8];
    virtual ic_fetch_if     vif;
    bit [2:0]               slot, reply_slot;
    ic_xact                 xacts[8];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        foreach (seq_item_ports[i])
            seq_item_ports[i] = new($sformatf("port%0d", i), this);
        assert(uvm_config_db#(virtual ic_fetch_if)::get(this, "", "vif", vif));
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            begin 
                forever @(posedge vif.clk) begin
                    ++slot;
                    req = xacts[slot];
                    if (!req) begin
                        seq_item_ports[slot].try_next_item(req);
                        xacts[slot] = req;
                    end
                    if (req) begin
                        vif.fetch_addr <= xacts[slot].addr;
                        vif.fetch_en <= 1;
                    end else begin
                        vif.fetch_en <= 0;
                    end
                    reply_slot = slot - 3;
                    if (vif.fetch_valid) begin
                        req = xacts[reply_slot];
                        if (req) begin
                            req.data = vif.fetch_data;
                            seq_item_ports[reply_slot].item_done(req);
                            xacts[reply_slot] = null;
                        end else begin
                            `uvm_error(get_type_name(), "Fetch asserted valid but no previous related request.");
                        end
                    end
                end
            end 
        join_none
    endtask

endclass