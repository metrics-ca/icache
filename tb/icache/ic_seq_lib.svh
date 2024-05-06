class ic_single_seq extends uvm_sequence#(ic_xact);
    `uvm_object_utils(ic_single_seq)
    
    function new(string name = "");
        super.new(name);
    endfunction

    task body();
        req = ic_xact::type_id::create("req");
        start_item(req);
        if (!req.randomize( ))
            `uvm_error(get_type_name(), "Failed to randomize transaction")
        finish_item(req);
    endtask
endclass

class ic_typical_seq extends uvm_sequence#(ic_xact);
    `uvm_object_utils(ic_typical_seq)

    function new(string name = "");
        super.new(name);
    endfunction

    task body();
        bit [4:0]   n_insns;
        ic_xact     init_req;

        this.randomize(n_insns) with { n_insns > 0; };
        init_req = ic_xact::type_id::create("init_req");
        void'(init_req.randomize());

        `uvm_info(get_type_name(), $sformatf("fetching range: %0h - %0h", init_req.addr * 2, (init_req.addr + n_insns - 1) * 2), UVM_LOW);
        for (int i = 0; i < n_insns; i++) begin
            req = ic_xact::type_id::create("req");
            req.addr = init_req.addr;
            
            // Driver will retry until a (partial) hit.
            start_item(req);
            finish_item(req);

            // Request next address in series.
            get_response(rsp);
            if (rsp.data[1:0] == 2'b11)
                init_req.addr += 2; // words
            else
                init_req.addr += 1;
        end
    endtask
endclass
