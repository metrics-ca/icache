// icache fetch transaction
class ic_xact extends uvm_sequence_item;
    rand bit [26:1] addr;
    logic [1:0]     hit;
    logic [31:0]    data;

    `uvm_object_utils_begin(ic_xact)
        `uvm_field_int(addr, UVM_HEX)
        `uvm_field_int(hit, UVM_BIN)
        `uvm_field_int(data, UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "");
        super.new(name);
    endfunction
endclass
