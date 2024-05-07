class ic_typical_test extends ic_base_test;
    `uvm_component_utils(ic_typical_test);

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task main_phase(uvm_phase phase);
        bit [7:0]       active;
        int             n_threads = 1;
        int             n_trans = 10;

        super.main_phase(phase);
        phase.raise_objection(this);
        $value$plusargs("threads=%d", n_threads);
        $value$plusargs("trans=%d", n_trans);
        `uvm_info(get_type_name(), $sformatf("Using %0d threads", n_threads), UVM_LOW);
        void'(randomize(active) with { $countones(active) == n_threads; });
        `uvm_info(get_type_name(), $sformatf("Threads active: %b", active), UVM_LOW);
        for (int i = 0; i < 8; i++)
            if (active[i])
                fork
                    int     i_shadow = i;
                
                    begin 
                        ic_typical_seq   seq;
                        
                        for (int j = 0; j < n_trans; j++) begin
                            $cast(seq, ic_typical_seq::type_id::create("seq"));
                            seq.start(env.fetch_agent.sqr[i_shadow]);
                        end
                    end
                join_none
        wait fork;
        phase.drop_objection(this);
    endtask
endclass