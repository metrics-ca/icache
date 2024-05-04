class ic_env extends uvm_env;
    `uvm_component_utils(ic_env)

    ic_agent    fetch_agent;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fetch_agent = ic_agent::type_id::create("fetch_agent", this);
    endfunction

endclass