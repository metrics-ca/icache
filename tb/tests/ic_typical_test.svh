class ic_typical_test extends ic_base_test;
    `uvm_component_utils(ic_typical_test);

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        fork
            begin 
                ic_typical_seq   seq;
                
                $cast(seq, ic_typical_seq::type_id::create("seq"));

                phase.raise_objection(this);
                seq.start(env.fetch_agent.sqr[0]);
                phase.drop_objection(this);
            end
        join_none
    endtask
endclass