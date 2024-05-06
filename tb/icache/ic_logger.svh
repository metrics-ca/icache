class ic_logger extends uvm_component;
    `uvm_component_utils(ic_logger);

    uvm_analysis_imp#(ic_xact, ic_logger)   ap;
    int                                     fd;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
        fd = $fopen("ic_xact.log");
    endfunction

    function void write(ic_xact item);
        if (item.hit)
            $fdisplay(fd, "@%0t: %h: hit, data = %h", $time, item.addr * 2, item.data);
        else
            $fdisplay(fd, "@%0t: %h: miss", $time, item.addr * 2);
    endfunction
endclass
            
        