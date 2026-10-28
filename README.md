# 5-Stage Pipelined RISC-V CPU (Early Prototype)

A learning project to implement a small subset of RV32I in SystemVerilog and verify it with a self-checking testbench.

## Current scope
- Five pipeline stages represented explicitly: IF, ID, EX, MEM, WB.
- Supports a deliberately small instruction subset in this starter: `ADDI`, `ADD`, `SUB`, `AND`, `OR`, `XOR`.
- Register x0 is hard-wired to zero.
- A testbench runs a short program and checks register results.

## Not implemented yet
Load/store instructions, branch handling, data forwarding, load-use stalls, hazard/flush logic, a randomized regression, and full RV32I coverage are future work. This repository is an early working foundation, not a complete processor.

## Run
Requires Icarus Verilog (`iverilog` and `vvp`).

```sh
iverilog -g2012 -o sim rtl/rv32i_alu.sv rtl/pipelined_cpu.sv tb/tb_pipelined_cpu.sv
vvp sim
```

Expected output includes `PASS: pipeline ALU smoke test`.
