// icache fetch transaction
class ic_xact extends uvm_object;
    bit [26:1]      addr;
    logic           hit;
    logic [31:0]    data;

    `uvm_object_utils_begin(ic_xact)
        `uvm_field_int(addr, UVM_HEX)
        `uvm_field_int(hit, 0)
        `uvm_field_int(data, UVM_HEX)
    `uvm_object_utils_end
endclass
