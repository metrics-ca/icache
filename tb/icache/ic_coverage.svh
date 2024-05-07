class ic_coverage extends uvm_component;
    `uvm_component_utils(ic_coverage)
    
    uvm_analysis_imp#(ic_xact, ic_coverage)           ap;

    bit [7:0]       line;
    bit [3:1]       word;
    bit [1:0]       hit;

    covergroup cg;
        option.per_instance = 1;
        coverpoint  line;
        coverpoint  word;
        coverpoint  hit {
            bins both = { 2'b11 };
            bins one = { 2'b01 };
            ignore_bins none = { 2'b00 };
            illegal_bins two = { 2'b10 };
        }
        word_x_valid: cross word, hit {
            bins dbl = binsof(hit.both) && binsof(word) intersect { [0:6] };
            bins sgl = binsof(hit.one) && binsof(word) intersect { 7 };
        }
    endgroup
        
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
        cg = new;
    endfunction

    function void write(ic_xact item);
        line = item.addr[11:4];
        word = item.addr[3:1];
        hit = item.hit;
        if (hit)
            cg.sample();
    endfunction
endclass