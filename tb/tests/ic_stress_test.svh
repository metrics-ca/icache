class ic_stress_test extends ic_base_test;
    `uvm_component_utils(ic_stress_test);

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        phase.raise_objection(this);
        for (int i = 0; i < 8; i++)
            fork
                int     i_shadow = i;
                
                begin 
                    for (int j = 0; j < 100; j++) begin
                        ic_single_seq   seq;
                        
                        $cast(seq, ic_single_seq::type_id::create("seq"));
                        seq.start(env.fetch_agent.sqr[i_shadow]);
                    end
                end
            join_none
        wait fork;
        phase.drop_objection(this);
    endtask
endclass