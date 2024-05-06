class dram_ctrl_agent extends uvm_agent;
    `uvm_component_utils(dram_ctrl_agent)

    dram_ctrl_monitor      monitor;
    dram_ctrl_logger       logger;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = dram_ctrl_monitor::type_id::create("monitor", this);
        logger = dram_ctrl_logger::type_id::create("logger", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.ap.connect(logger.ap);
    endfunction
endclass