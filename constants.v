`ifndef CONSTANTS_V
`define CONSTANTS_V

// =============================================================
// constants.v
// -------------------------------------------------------------
// Central place for all instruction, register, bus and ALU codes.
// Keeping these values in one file makes the CPU easier to explain
// and prevents mismatches between modules.
// =============================================================

// -------------------------------------------------------------
// Instruction opcodes: instruction[15:12]
// -------------------------------------------------------------
`define OP_LDI    4'h0   // Load immediate:      Rx = immediate
`define OP_MOV    4'h1   // Move register:       Rx = Ry
`define OP_ADD    4'h2   // Add:                 Rx = Rx + Ry
`define OP_SUB    4'h3   // Subtract:            Rx = Rx - Ry
`define OP_AND    4'h4   // Bitwise AND:         Rx = Rx & Ry
`define OP_OR     4'h5   // Bitwise OR:          Rx = Rx | Ry
`define OP_XOR    4'h6   // Bitwise XOR:         Rx = Rx ^ Ry
`define OP_INC    4'h7   // Increment:           Rx = Rx + 1
`define OP_LOAD   4'h8   // Load data memory:    Rx = MEM[imm]
`define OP_STORE  4'h9   // Store data memory:   MEM[imm] = Rx
`define OP_JMP    4'hA   // Unconditional jump:  PC = imm
`define OP_BEQ    4'hB   // Branch if zero:      if zero_flag PC = imm
`define OP_HALT   4'hF   // Stop processor

// -------------------------------------------------------------
// Register IDs: instruction[11:10] = Rx, instruction[9:8] = Ry
// -------------------------------------------------------------
`define REG_R0    2'b00
`define REG_R1    2'b01
`define REG_R2    2'b10

// -------------------------------------------------------------
// Bus source codes
// These control the shared bus multiplexer.
// -------------------------------------------------------------
`define BUS_ZERO   4'h0   // Put 0 on the bus
`define BUS_REG    4'h1   // Put selected register output on the bus
`define BUS_G      4'h2   // Put G register output on the bus
`define BUS_IMM    4'h3   // Put zero-extended immediate on the bus
`define BUS_MEM    4'h4   // Put data memory output on the bus

// -------------------------------------------------------------
// ALU operation codes
// -------------------------------------------------------------
`define ALU_ADD    3'b000
`define ALU_SUB    3'b001
`define ALU_AND    3'b010
`define ALU_OR     3'b011
`define ALU_XOR    3'b100
`define ALU_INC    3'b101

`endif
