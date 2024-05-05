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
