package ic_pkg;

// Constants defined by desired implementation
localparam  WAYS = 4;
localparam  BYTES_PER_LINE = 16;
localparam  LINES = 256;
localparam  ADDR_BITS = 27;     // 128MB - size of Tang Primer 20K DRAM

// Derived constants
localparam  WORDS_PER_LINE = BYTES_PER_LINE/4;
localparam  LG_WAYS = $clog2(WAYS);
localparam  LG_BYTES = $clog2(BYTES_PER_LINE);
localparam  LG_LINES = $clog2(LINES);
localparam  TAG_BITS = ADDR_BITS - LG_BYTES - LG_LINES;

// Data memory:
// Data memory is implemented as two memories: one for "even" words and one for "odd" words.
// A compact instruction requires data from one memory; a 32-bit instruction requires data from both.
// Address is combination of offset within line, and line.
localparam  DATA_ABITS = LG_LINES + LG_BYTES - 1;
localparam  DATA_DBITS = 16;

localparam  LRU_BITS = WAYS * LG_WAYS;

typedef logic [LG_BYTES-1:2]          ic_waddr_t;
typedef logic [LG_WAYS-1:0]           ic_way_t;
typedef logic [LG_LINES-1:0]          ic_line_t;
typedef logic [TAG_BITS-1:0]          ic_tag_t;
typedef logic [WAYS-1:0][LG_WAYS-1:0] ic_lru_t;
typedef logic [WORDS_PER_LINE-1:0][15:0]  ic_fill_t;

typedef struct packed {
    reg         valid;
    ic_tag_t    tag;
} ic_tag_entry_t;

typedef enum { BEHAVIORAL, GOWIN } eImplementation;

localparam eImplementation IMPL = GOWIN;

endpackage