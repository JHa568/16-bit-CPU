`timescale 1ns / 1ps
`include "constants.v"

// =============================================================
// instruction_memory.v
// -------------------------------------------------------------
// Read-only instruction memory containing the test program.
//
// Instruction format, 16 bits total:
//   [15:12] opcode
//   [11:10] Rx
//   [9:8]   Ry
//   [7:0]   immediate / memory address / jump target
//
// The PC supplies address. The selected instruction is output.
// =============================================================

module instruction_memory(
    input      [7:0]  address,
    output     [15:0] instruction
);

    reg [15:0] memory [0:255];
    integer i;

    initial begin
        // Default everything to HALT so unused memory is safe.
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = {`OP_HALT, 12'd0};
        end

        // -----------------------------------------------------
        // Program used to test all extension features.
        // Expected final values:
        //   R0 = 0
        //   R1 = 7
        //   R2 = 7
        //   R3 = 9
        //   data_memory[20] = 7
        //   zero_flag = 1
        // -----------------------------------------------------

        memory[0]  = {`OP_LDI,   `REG_R0, `REG_R0, 8'd5};   // R0 = 5
        memory[1]  = {`OP_LDI,   `REG_R1, `REG_R0, 8'd3};   // R1 = 3
        memory[2]  = {`OP_ADD,   `REG_R0, `REG_R1, 8'd0};   // R0 = 5 + 3 = 8
        memory[3]  = {`OP_SUB,   `REG_R0, `REG_R1, 8'd0};   // R0 = 8 - 3 = 5
        memory[4]  = {`OP_MOV,   `REG_R2, `REG_R0, 8'd0};   // R2 = R0 = 5
        memory[5]  = {`OP_AND,   `REG_R2, `REG_R1, 8'd0};   // R2 = 5 & 3 = 1
        memory[6]  = {`OP_OR,    `REG_R2, `REG_R1, 8'd0};   // R2 = 1 | 3 = 3
        memory[7]  = {`OP_XOR,   `REG_R2, `REG_R0, 8'd0};   // R2 = 3 ^ 5 = 6
        memory[8]  = {`OP_INC,   `REG_R2, `REG_R0, 8'd0};   // R2 = 6 + 1 = 7
        memory[9]  = {`OP_STORE, `REG_R2, `REG_R0, 8'd20};  // MEM[20] = R2 = 7
        memory[10] = {`OP_LOAD,  `REG_R1, `REG_R0, 8'd20};  // R1 = MEM[20] = 7
        memory[11] = {`OP_SUB,   `REG_R0, `REG_R0, 8'd0};   // R0 = R0 - R0 = 0, zero_flag=1
        memory[12] = {`OP_BEQ,   `REG_R0, `REG_R0, 8'd14};  // If zero, jump to 14
        memory[13] = {`OP_LDI,   `REG_R2, `REG_R0, 8'd255}; // Skipped if BEQ works
        memory[14] = {`OP_LDI,   `REG_R3, `REG_R0, 8'd9};   // R3 = 9
        memory[15] = {`OP_JMP,   `REG_R0, `REG_R0, 8'd17};  // Jump to HALT
        memory[16] = {`OP_LDI,   `REG_R1, `REG_R0, 8'd255}; // Skipped if JMP works
        memory[17] = {`OP_HALT,  12'd0};                    // Stop
    end

    assign instruction = memory[address];

endmodule
