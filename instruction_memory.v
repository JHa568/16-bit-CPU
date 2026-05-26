`timescale 1ns / 1ps

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
    // ---- Load phase ----
    memory[0]  = 16'b0000_00_00_00001010; // LDI R0, 10
    memory[1]  = 16'b0000_01_00_00010100; // LDI R1, 20
    memory[2]  = 16'b0000_10_00_00011110; // LDI R2, 30

    // ---- Push phase ----
    memory[3]  = 16'b1100_00_00_00000000; // PUSH R0  mem[FF]=10, SP=FE
    memory[4]  = 16'b1100_01_00_00000000; // PUSH R1  mem[FE]=20, SP=FD
    memory[5]  = 16'b1100_10_00_00000000; // PUSH R2  mem[FD]=30, SP=FC

    // ---- Clear phase ----
    memory[6]  = 16'b0000_00_00_00000000; // LDI R0, 0
    memory[7]  = 16'b0000_01_00_00000000; // LDI R1, 0
    memory[8]  = 16'b0000_10_00_00000000; // LDI R2, 0

    // ---- Pop phase ----
    memory[9]  = 16'b1101_00_00_00000000; // POP R0  R0=30, SP=FD
    memory[10] = 16'b1101_01_00_00000000; // POP R1  R1=20, SP=FE
    memory[11] = 16'b1101_10_00_00000000; // POP R2  R2=10, SP=FF

    // ---- Stop ----
    memory[12] = 16'b1111_00_00_00000000; // HALT
end

assign instruction = memory[address];

endmodule
