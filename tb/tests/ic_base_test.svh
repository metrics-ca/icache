class ic_base_test extends uvm_test;
    `uvm_component_utils(ic_base_test)

    ic_env      env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = new("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            begin 
                uvm_top.print_topology();
            end
        join_none
    endtask
endclass
