class dram_ctrl_logger extends uvm_component;
    `uvm_component_utils(dram_ctrl_logger);

    uvm_analysis_imp#(dram_ctrl_xact, dram_ctrl_logger)   ap;
    int                                     fd;
    const string                            cmds[8] = '{ "write", "read", "(2)", "(3)", "(4)", "(5)", "(6)", "(7)" };

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
        fd = $fopen("dram_xact.log");
    endfunction

    function void write(dram_ctrl_xact item);
        $fwrite(fd, "@%0t: %5s %h ", $time, cmds[item.cmd], item.addr);
        for (int i = 15; i >= 0; i--) begin
            if (item.mask[i])
                $fwrite(fd, "%02h", item.data[i*8+:8]);
            else
                $fwrite(fd, "--");
            if (!i[1:0])
                $fwrite(fd, " ");
        end
        $fdisplay(fd);
    endfunction
endclass
            
        