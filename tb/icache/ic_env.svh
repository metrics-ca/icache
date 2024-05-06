class ic_env extends uvm_env;
    `uvm_component_utils(ic_env)

    ic_agent        fetch_agent;
    dram_ctrl_agent dram_agent;
    ic_scoreboard   sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fetch_agent = ic_agent::type_id::create("fetch_agent", this);
        dram_agent = dram_ctrl_agent::type_id::create("dram_agent", this);
        sb = ic_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        fetch_agent.monitor.ap.connect(sb.fetch_ap);
        dram_agent.monitor.ap.connect(sb.dram_ap);
    endfunction
endclass