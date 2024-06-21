8-context barrel processor

# Pipe Stages

## Stage 0:

Initiated in `ic_decode` module.

`sch_ic_go` requests that a context fetch an instruction.

`sch_ic_pc` is the PC to fetch from.

## Stages 1-2: Instruction Cache

Stage 1: fetch tag, LRU RAMs and compare tag

Stage 2: fetch data from data RAM

## Stage 3: Initial decode

Fetch data from instruction cache is reconstructed to form 16/32-bit
instruction word `ic_cpu_insn_q3`.

Basic decoding is done to identify register file fetches and stores.

`ic_cpu_ra_n3` and `ic_cpu_ra_en_n3` control read port A.

`ic_cpu_rb_n3` and `ic_cpu_rb_en_n3` control read port B.

These are not flopped since register file BSRAM does the flopping.

`ic_cpu_rd_q3` and `ic_cpu_rd_en_q3` control write port D.  These are flopped, and must be carried through datapath to final writeback.

`ic_cpu_ctx_en_q3` indicates if the context should be processing an instruction.  This may be set even if none of the register file enables are set, if an instruction does not access the register file at all.


## Stage 4: Register Fetch

A BSRAM register file contains the integer register file for 8 contexts (256 words of 64 bits = 16K bits).  The floating point register file can fit in the same BSRAM.

This stage also decodes the instruction completely, and works out all immediate values.

## Stage 5: ALU

This stage performs all ALU operations.  With the exception of multiplication and division, all integer ops are expected to complete in one clock.

## Stage 6: Writeback

This stage writes back the ALU result to the register file.

This stage is also the point where the outcome of a branch is known,
so the next PC can be computed.

# Pipeline Bubbles

If an instruction fetch misses in the instruction cache, then it must be retried.  `ic_cpu_ctx_en_q3` will be low in this case.

Later stages (RF and ALU) may determine that an instruction needs to be retried.  On a retry, the same instruction is fetched again from the same PC, and the same register file fetches occur.  Retry is appropriate if a resource is not available, e.g. the divider is busy with another instruction.

However, retry may not be appropriate if an instruction must pause. e.g. if we execute a divide, then WE will make the divider busy, and will need to miss out on subsequent cycles.  However, in this case, the divider is committed (state change) so retry is not appropriate.  Rather, the resource must "wake up" the processor so that an instruction (and writeback) completes even though none was issued in that time slot.

