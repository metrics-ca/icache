class ic_monitor extends uvm_monitor;
    `uvm_component_utils(ic_monitor);

    virtual ic_fetch_if     vif;
    ic_xact                 item;
    bit [26:1]              addr[$];
    bit                     en[$];
    uvm_analysis_port#(ic_xact) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        assert(uvm_config_db#(virtual ic_fetch_if)::get(this, "", "vif", vif));
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            forever @(posedge vif.clk) begin
                if (addr.size() == 3) begin
                    if (en[0]) begin
                        item = new;
                        item.addr = addr[0];
                        item.hit = vif.fetch_valid;
                        item.data = vif.fetch_data;
                        ap.write(item);
                    end else if (vif.fetch_valid) begin
                        `uvm_error(get_type_name(), "hit without prior fetch!");
                    end
                    addr.pop_front();
                    en.pop_front();
                end
                addr.push_back(vif.fetch_addr);
                en.push_back(vif.fetch_en);
            end
        join_none
    endtask
endclass

                    


