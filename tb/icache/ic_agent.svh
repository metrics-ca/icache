class ic_agent extends uvm_agent;
    `uvm_component_utils(ic_agent)

    ic_driver       driver;
    ic_monitor      monitor;
    ic_logger       logger;
    ic_sqr_t        sqr[8];
    virtual ic_fetch_if fetch_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = ic_driver::type_id::create("driver", this);
        monitor = ic_monitor::type_id::create("monitor", this);
        logger = ic_logger::type_id::create("logger", this);
        assert(uvm_config_db#(virtual ic_fetch_if)::get(this, "", "vif", fetch_if));
        foreach (sqr[i])
            sqr[i] = ic_sqr_t::type_id::create($sformatf("sequencer%0d", i), this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.ap.connect(logger.ap);
        foreach (sqr[i])
            driver.seq_item_ports[i].connect(sqr[i].seq_item_export);
    endfunction
endclass