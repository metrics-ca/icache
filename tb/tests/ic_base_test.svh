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

    task reset_phase(uvm_phase phase);
        super.reset_phase(phase);
        fork begin
            phase.raise_objection(this);
            uvm_top.print_topology();
            
            // Wait until reset deasserted
            #100;

            // Wait until IC cache controller can accept transactions
            wait (env.fetch_agent.fetch_if.init_done == 1);
            phase.drop_objection(this);
        end join_none
    endtask

    task shutdown_phase(uvm_phase phase);
        super.shutdown_phase(phase);
        phase.raise_objection(this);
        
        // To move the waveform off the last transaction
        #100;

        phase.drop_objection(this);
    endtask
endclass
