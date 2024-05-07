class ic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ic_scoreboard)

    uvm_analysis_imp#(dram_ctrl_xact, ic_scoreboard)    dram_ap;
    uvm_analysis_imp#(ic_xact, ic_scoreboard)           fetch_ap;

    bit [15:0]  shadow[int];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        dram_ap = new("dram_ap", this);
        fetch_ap = new("fetch_ap", this);
    endfunction

    function void check_ic(int addr, bit [15:0] actual);
        bit [15:0]  expected;
        
        if (!shadow.exists(addr)) begin
            `uvm_error(get_type_name(), $sformatf("Address %0h not read from DRAM yet.", addr));
        end else begin
            expected = shadow[addr];
            if (expected != actual)
                `uvm_error(get_type_name(), $sformatf("Data mismatch: address %0h: expected (DRAM) %04h fetched %04h", addr * 2, expected, actual));
        end
    endfunction

    function void write(uvm_object item);
        ic_xact         ic_item;
        dram_ctrl_xact  dram_item;
        bit [26:1]      addr;

        if ($cast(dram_item, item)) begin
            // Received line from DRAM - update shadow
            addr = dram_item.addr[26:1];
            for (int i = 0; i < 8; i++)
                shadow[addr+i] = dram_item.data[i*16+:16];

        end else if ($cast(ic_item, item)) begin
            addr = ic_item.addr;
            if (ic_item.hit[0])
                check_ic(addr, ic_item.data[15:0]);
            if (ic_item.hit[1])
                check_ic(addr+1, ic_item.data[31:16]);
        end else begin
            `uvm_error(get_type_name(), "Received strange item.");
        end
    endfunction
endclass