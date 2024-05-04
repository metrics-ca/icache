class ic_driver extends uvm_driver#(ic_xact);
    `uvm_component_utils(ic_driver)

    virtual ic_fetch_if     vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        assert(uvm_config_db#(virtual ic_fetch_if)::get(this, "", "vif", vif));
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            begin 
                forever @(posedge vif.clk) begin
                    seq_item_port.try_next_item(req);
                    if (req) begin
                        vif.fetch_addr <= req.addr;
                        vif.fetch_en <= 1;
                        seq_item_port.item_done();
                    end else begin
                        vif.fetch_en <= 0;
                    end
                end
            end 
        join_none
    endtask

endclass