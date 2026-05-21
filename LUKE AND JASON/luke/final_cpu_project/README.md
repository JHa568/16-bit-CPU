# Final ELEC2602 CPU Extension Project

This is a clean rebuild using the control-plane style from the tutor-approved essential design.

## Architecture

The CPU uses:

- Program Counter (`pc.v`)
- Instruction Memory (`instruction_memory.v`)
- Instruction Register (`instruction_register.v`)
- Controller FSM with packed control plane (`controller_fsm.v` + `controller_tasks.v`)
- Shared bus multiplexer (`bus_mux.v`)
- Register file with R0-R3 (`register_file.v`)
- A and G registers (`register_16.v`)
- ALU with ADD, SUB, AND, OR, XOR, INC (`ALU.v`)
- Data memory (`data_memory.v`)
- Status register with zero flag (`status_register.v`)
- FPGA wrapper for DE1-SoC (`fpga_top.v`)

## Instruction Format

16-bit instruction:

```text
[15:12] opcode
[11:10] Rx
[9:8]   Ry
[7:0]   immediate / memory address / jump target
```

## Supported Instructions

```text
LDI   Rx, imm       Rx = imm
MOV   Rx, Ry        Rx = Ry
ADD   Rx, Ry        Rx = Rx + Ry
SUB   Rx, Ry        Rx = Rx - Ry
AND   Rx, Ry        Rx = Rx & Ry
OR    Rx, Ry        Rx = Rx | Ry
XOR   Rx, Ry        Rx = Rx ^ Ry
INC   Rx            Rx = Rx + 1
LOAD  Rx, [addr]    Rx = memory[addr]
STORE Rx, [addr]    memory[addr] = Rx
JMP   addr          PC = addr
BEQ   addr          if zero_flag == 1, PC = addr
HALT                stop processor
```

## Simulation Command

```bash
iverilog -o final_cpu.vvp \
constants.v ALU.v register_16.v register_file.v bus_mux.v pc.v \
instruction_memory.v instruction_register.v data_memory.v status_register.v \
controller_tasks.v controller_fsm.v processor_top.v processor_TB.v

vvp final_cpu.vvp

gtkwave final_cpu.vcd
```

## Expected Final Simulation Values

```text
R0 = 0
R1 = 7
R2 = 7
R3 = 9
MEM[20] = 7
zero_flag = 1
halted = 1
```

## FPGA Setup

Use top-level entity:

```text
fpga_top
```

Board: DE1-SoC / Cyclone V 5CSEMA5F31C6.

Display mapping:

```text
HEX0 = R1 low nibble
HEX1 = R2 low nibble
HEX2 = R3 low nibble
HEX3 = PC low nibble
HEX4 = current opcode
HEX5 = controller state
LEDR[7:0] = PC
LEDR[8] = halted
LEDR[9] = cpu clock
KEY0 = reset
SW0 = speed select
```
