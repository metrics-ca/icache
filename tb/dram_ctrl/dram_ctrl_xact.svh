// icache fetch transaction
class dram_ctrl_xact extends uvm_sequence_item;
    rand bit [2:0]      cmd;
    rand bit [27:0]     addr;
    rand logic [127:0]  data;
    rand logic [15:0]   mask;

    `uvm_object_utils_begin(dram_ctrl_xact)
        `uvm_field_int(cmd, 0)
        `uvm_field_int(addr, UVM_HEX)
        `uvm_field_int(data, UVM_HEX)
        `uvm_field_int(mask, UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "");
        super.new(name);
    endfunction
endclass
