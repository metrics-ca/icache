`include "uvm_macros.svh"

package tb_icache_pkg;
import uvm_pkg::*;
import tb_dram_ctrl_pkg::*;

// Fetch port agent
`include "ic_xact.svh"
`include "ic_driver.svh"
typedef uvm_sequencer#(ic_xact) ic_sqr_t;
`include "ic_monitor.svh"
`include "ic_logger.svh"
`include "ic_agent.svh"

// Envrionment
`include "ic_scoreboard.svh"
`include "ic_env.svh"
`include "ic_seq_lib.svh"
`include "ic_base_test.svh"
`include "ic_single_test.svh"
`include "ic_typical_test.svh"
`include "ic_stress_test.svh"

endpackage

