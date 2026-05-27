`timescale 1ns / 1ps
`include "constants.v"
// =============================================================
// instruction_memory.v  —  PUSH / POP testbench program
// -------------------------------------------------------------
// Program flow:
//   1. Load R0=10, R1=20, R2=30
//   2. PUSH R0, R1, R2  (SP goes FF->FE->FD->FC)
//   3. Clear R0, R1, R2 to 0  (proves POP restores them)
//   4. POP  R0, R1, R2  (LIFO: R0=30, R1=20, R2=10, SP->FF)
//   5. HALT
// =============================================================

module instruction_memory(
    input  [7:0]  address,
    output [15:0] instruction
);

reg [15:0] memory [255:0];

initial begin
    // // ---- Load phase ----
    // memory[0]  = 16'b0000_00_00_00001010; // LDI R0, 10
    // memory[1]  = 16'b0000_01_00_00010100; // LDI R1, 20
    // memory[2]  = 16'b0000_10_00_00011110; // LDI R2, 30

    // // ---- Push phase ----
    // memory[3]  = 16'b1100_00_00_00000000; // PUSH R0  mem[FF]=10, SP=FE
    // memory[4]  = 16'b1100_01_00_00000000; // PUSH R1  mem[FE]=20, SP=FD
    // memory[5]  = 16'b1100_10_00_00000000; // PUSH R2  mem[FD]=30, SP=FC

    // // ---- Clear phase ----
    // memory[6]  = 16'b0000_00_00_00000000; // LDI R0, 0
    // memory[7]  = 16'b0000_01_00_00000000; // LDI R1, 0
    // memory[8]  = 16'b0000_10_00_00000000; // LDI R2, 0

    // // ---- Pop phase ----
    // memory[9]  = 16'b1101_00_00_00000000; // POP R0  R0=30, SP=FD
    // memory[10] = 16'b1101_01_00_00000000; // POP R1  R1=20, SP=FE
    // memory[11] = 16'b1101_10_00_00000000; // POP R2  R2=10, SP=FF

    // // ---- SIMD Phase ----
    memory[0]  = 16'b0000_00_00_00001010; // LDI R0, 0x12
    // memory[0]  = 16'b0000_00_00_00001010; // LDI R0, 10
    memory[1]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[2]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[3]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[4]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[5]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[6]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[7]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[8]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0

    memory[9]  = 16'b0000_01_00_00010100; // LDI R1, 20 15:
    memory[10]  = {`OP_OR, `REG_R0, `REG_R1, 8'd0}; // OR R0, R1


    memory[11]  = 16'b0000_01_00_00011110; // LDI R1, 30
    memory[12]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1
    memory[13]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1
    memory[14]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1
    memory[15]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1
    memory[16]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1
    memory[17]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1
    memory[18]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1
    memory[19]  = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R1, R1



    memory[20]  = 16'b0000_10_00_00010100; // LDI R2, 20
    memory[21]  = {`OP_OR, `REG_R1, `REG_R2, 8'd0}; // OR R1, R2
    
    memory[22] = {`OP_SIMD, `ALU_ADD, `M_SIMD_2X8, `REG_R0, `REG_R1, 3'd0}; // SIMD ALU_ADD R2 R1 R0
    memory[23] = {`OP_SIMD, `ALU_SUB, `M_SIMD_2X8, `REG_R0, `REG_R1, 3'd0}; // SIMD ALU_ADD R2 R1 R0

    // memory[24] = 16'b1111_00_00_00000000; // HALT

      // ---- SIMD 4x4 Phase ----
    // R0 = 0x1234
    // lanes: [1,2,3,4]
    
    memory[24] = 16'b0000_00_00_00010010; // LDI R0, 0x12
    memory[25] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // shift/build upper nibble
    memory[26] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};
    memory[27] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};
    memory[28] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};
    memory[29] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[30] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[31] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[32] = {`OP_ADD, `REG_R0, `REG_R0, 8'd0}; // ADD R0, R0
    memory[33] = 16'b0000_01_00_00110100; // LDI R1, 0x34
    memory[34] = {`OP_OR, `REG_R0, `REG_R1, 8'd0}; // R0 = 0x1234

    memory[35] = 16'b0000_01_00_00010001; // LDI R1, 0x11
    memory[36] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0};
    memory[37] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0};
    memory[38] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0};
    memory[39] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0};
    memory[40] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R0, R0
    memory[41] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R0, R0
    memory[42] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R0, R0
    memory[43] = {`OP_ADD, `REG_R1, `REG_R1, 8'd0}; // ADD R0, R0

    memory[44] = 16'b0000_10_00_00010001; // LDI R2, 0x11
    memory[45] = {`OP_OR, `REG_R1, `REG_R2, 8'd0}; // R1 = 0x1111

    // // SIMD 4x4 ADD
    // // Expected:
    // //   0x1234
    // // + 0x1111
    // // = 0x2345
    memory[46] = {`OP_SIMD, `ALU_ADD,`M_SIMD_4X4,`REG_R0,`REG_R1, 3'b0}; // SIMD ADD 4x4: R0 + R1
    
    // ---- Stop ----
    memory[47] = 16'b1111_00_00_00000000; // HALT
end

assign instruction = memory[address];

endmodule
