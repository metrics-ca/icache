class ic_driver extends uvm_driver#(ic_xact);
    `uvm_component_utils(ic_driver)

    uvm_seq_item_pull_port#(ic_xact, ic_xact) seq_item_ports[8];
    virtual ic_fetch_if     vif;
    bit [2:0]               slot, reply_slot;
    ic_xact                 xacts[8];
    bit [31:0]              data;
    bit [1:0]               hit;
    
    // Latency from driving to sampling result:
    // cycle 0: drive fetch_en (NBA)
    // cycle 1: DUT sees fetch_en, issues read from tag RAM
    // cycle 2: DUT issues read from data RAM
    // cycle 3: DUT reformats result, drivces fetch_data (NBA)
    // cycle 4: driver sees data
    const int               LATENCY = 4;

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
                    // try_next_item() will nudge you into the NBA region.
                    // Sample anything required now.
                    data = vif.fetch_data;
                    hit = vif.fetch_valid;
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
                    reply_slot = slot - LATENCY;
                    if (|hit) begin
                        req = xacts[reply_slot];
                        if (req) begin
                            req.data = data;
                            req.hit = hit;
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