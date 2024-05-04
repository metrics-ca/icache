class ic_agent extends uvm_agent;
    `uvm_component_utils(ic_agent)

    ic_driver       driver;
    ic_sqr_t        sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = ic_driver::type_id::create("driver", this);
        sqr = ic_sqr_t::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass