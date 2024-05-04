`include "uvm_macros.svh"

package tb_icache_pkg;
import uvm_pkg::*;

// Fetch port agent
`include "ic_xact.svh"
`include "ic_driver.svh"
typedef uvm_sequencer#(ic_xact) ic_sqr_t;
`include "ic_agent.svh"

// Envrionment
`include "ic_env.svh"
`include "ic_base_test.svh"

endpackage

