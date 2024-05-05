class ic_agent extends uvm_agent;
    `uvm_component_utils(ic_agent)

    ic_driver       driver;
    ic_sqr_t        sqr[8];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = ic_driver::type_id::create("driver", this);
        foreach (sqr[i])
            sqr[i] = ic_sqr_t::type_id::create($sformatf("sequencer%0d", i), this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        foreach (sqr[i])
            driver.seq_item_ports[i].connect(sqr[i].seq_item_export);
    endfunction
endclass