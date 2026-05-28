`timescale 1ns / 1ps
`include "constants.v"
// =============================================================
// instruction_memory.v — SIMD Average Function Demo
// -------------------------------------------------------------
//
// WHAT THIS PROGRAM DOES
// ──────────────────────
// Computes the average of two 8-bit values (A=10, B=20) using:
//   • SIMD 2×8 ADD  to multiply both lanes simultaneously (×3)
//   • AND mask      to unpack individual SIMD lanes to scalar
//   • Repeated scalar SUB loop  to implement divide (no divide opcode)
//   • PUSH / POP    to demonstrate a proper function call frame
//
// The function simd_avg(R0={A,B}) returns R0 = (3A + 3B) / 2 = 45
//
// INSTRUCTION FORMAT REMINDER
// ────────────────────────────
//   Standard : [15:12]=opcode  [11:10]=Rx  [9:8]=Ry  [7:0]=imm8
//   SIMD     : [15:12]=OP_SIMD [11:9]=alu_ctl [8:7]=mode
//                              [6:5]=Rx  [4:3]=Ry  [2:0]=000
//
// SIMD ENCODING USED
// ──────────────────
//   SIMD ADD 2×8 R0,R0 : 1110_000_01_00_00_000  (0xE080)
//   SIMD ADD 2×8 R0,R1 : 1110_000_01_00_01_000  (0xE088)
//   opcode=E  alu_ctl=000(ADD)  mode=01(2×8)  Rx=00(R0)  Ry=00/01
//
// REGISTER USAGE
// ──────────────
//   R0 = function argument / return value
//   R1 = scratch (callee-saved: pushed on entry, popped on exit)
//   R2 = scratch (callee-saved: pushed on entry, popped on exit)
//
// STACK LAYOUT DURING FUNCTION (full-descending, SP starts 0xFF)
// ───────────────────────────────────────────────────────────────
//   CALL site :  PUSH R0        → MEM[FF]=0x0A14,  SP=FE
//   Func entry:  PUSH R1        → MEM[FE]=caller_R1, SP=FD
//                PUSH R2        → MEM[FD]=caller_R2, SP=FC
//   Func exit :  POP  R2        → R2 restored,      SP=FD
//                POP  R1        → R1 restored,       SP=FE
//   Return site: POP  R1        → original R0 back in R1, SP=FF
//
// EXPECTED RESULT
// ───────────────
//   After HALT:  R0 = 45  (= (3*10 + 3*20) / 2)
//   The intermediate SIMD result R0={0x1E,0x3C}={30,60} is visible
//   at instruction 24 in simulation.
//
// ADDRESS MAP
// ───────────
//   0 – 12  MAIN: build inputs, PUSH R0, CALL (JMP 20)
//  13 – 14  RETURN SITE: POP R1, HALT
//  15 – 19  Padding (unused)
//  20 – 50  FUNCTION simd_avg
//              20-21  callee-save R1, R2
//              22-24  SIMD ×3 multiply
//              25-29  extract lo lane via AND mask
//              30-37  extract hi lane via ÷256 subtraction loop
//              38-46  scalar sum + ÷2 subtraction loop
//              47-50  move result, callee-restore, return (JMP 13)
// =============================================================

module instruction_memory(
    input  [7:0]  address,
    output [15:0] instruction
);

reg [15:0] memory [255:0];

initial begin

    // =========================================================
    // MAIN — build R0 = {A=10, B=20} = 0x0A14
    // =========================================================
    // LDI can only load 8-bit immediate into the low byte.
    // To put 10 in the HIGH byte we shift left 8 with 8× ADD doublings.

    memory[0]  = {`OP_LDI, `REG_R0, 2'b00, 8'd10};      // R0 = 0x000A
    memory[1]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x0014
    memory[2]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x0028
    memory[3]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x0050
    memory[4]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x00A0
    memory[5]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x0140
    memory[6]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x0280
    memory[7]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x0500
    memory[8]  = {`OP_ADD, `REG_R0, `REG_R0, 8'd0};     // R0 = 0x0A00  (10 << 8)
    memory[9]  = {`OP_LDI, `REG_R1, 2'b00, 8'd20};      // R1 = 0x0014  (B=20)
    memory[10] = {`OP_OR,  `REG_R0, `REG_R1, 8'd0};     // R0 = 0x0A14  {A=10, B=20}

    // =========================================================
    // CALL SETUP
    // ---------------------------------------------------------
    // Push R0 onto the stack so the caller can inspect the
    // original input after the function returns.
    // Then JMP to the function (addr 20).
    //
    // Note: this ISA has no indirect jump (JMP always uses imm8),
    // so the return address is baked into the function epilogue
    // as a hardcoded JMP 13.
    // =========================================================
    memory[11] = {`OP_PUSH, `REG_R0, 2'b00, 8'd0};      // PUSH R0 → MEM[FF]=0x0A14, SP→FE
    memory[12] = {`OP_JMP,  4'b0000, 8'd20};             // CALL: JMP simd_avg (addr 20)

    // =========================================================
    // RETURN SITE  (addr 13)
    // Function jumps back here when done.
    // =========================================================
    memory[13] = {`OP_POP,  `REG_R1, 2'b00, 8'd0};      // POP R1 ← original R0=0x0A14, SP→FF
    memory[14] = {`OP_HALT, 12'd0};                      // HALT — R0=45 is the average

    // =========================================================
    // Padding  (addr 15-19)
    // =========================================================
    memory[15] = {`OP_LDI, `REG_R2, 2'b00, 8'd0};       // padding / unused
    memory[16] = {`OP_LDI, `REG_R2, 2'b00, 8'd0};
    memory[17] = {`OP_LDI, `REG_R2, 2'b00, 8'd0};
    memory[18] = {`OP_LDI, `REG_R2, 2'b00, 8'd0};
    memory[19] = {`OP_LDI, `REG_R2, 2'b00, 8'd0};

    // =========================================================
    // FUNCTION: simd_avg
    // ---------------------------------------------------------
    // Input:   R0 = {A, B}  (8-bit values packed as SIMD 2×8)
    // Output:  R0 = (3*A + 3*B) / 2      [ = 45 for A=10, B=20 ]
    // Trashes: uses MEM[50] as a spill slot
    // Saves/restores R1, R2 (callee-saved convention)
    // =========================================================

    // ── Callee-save R1, R2 ───────────────────────────────────
    memory[20] = {`OP_PUSH, `REG_R1, 2'b00, 8'd0};      // PUSH R1 → MEM[FE], SP→FD
    memory[21] = {`OP_PUSH, `REG_R2, 2'b00, 8'd0};      // PUSH R2 → MEM[FD], SP→FC

    // ── Step 1: SIMD ×3 — multiply BOTH lanes simultaneously ─
    //
    //   Two SIMD ADD instructions process lane-hi and lane-lo
    //   in parallel. No carry can cross the 8-bit lane boundary.
    //
    //   R1 ← {A, B}              (original, used as addend)
    //   R0 ← SIMD_ADD(R0, R0)   → {2A, 2B}
    //   R0 ← SIMD_ADD(R0, R1)   → {3A, 3B} = {30, 60} = 0x1E3C
    //
    // SIMD encoding: [15:12]=E  [11:9]=000(ADD)  [8:7]=01(2×8)
    //                [6:5]=Rx   [4:3]=Ry   [2:0]=000
    memory[22] = {`OP_MOV,  `REG_R1, `REG_R0, 8'd0};    // R1 = {A,B} = 0x0A14
    memory[23] = {`OP_SIMD, `ALU_ADD, `M_SIMD_2X8, `REG_R0, `REG_R0, 3'b000}; // R0={2A,2B}=0x1428
    memory[24] = {`OP_SIMD, `ALU_ADD, `M_SIMD_2X8, `REG_R0, `REG_R1, 3'b000}; // R0={3A,3B}=0x1E3C

    // ── Step 2: Extract lo lane (3B=60) via AND mask ─────────
    //
    //   LDI R2, 255  → R2 = 0x00FF
    //   R1 = copy of R0 = 0x1E3C
    //   AND R1, R2   → R1 = 0x003C = 60  (only lo byte survives)
    memory[25] = {`OP_LDI, `REG_R2, 2'b00, 8'hFF};      // R2 = 0x00FF  (AND mask)
    memory[26] = {`OP_MOV, `REG_R1, `REG_R0, 8'd0};     // R1 = 0x1E3C  copy
    memory[27] = {`OP_AND, `REG_R1, `REG_R2, 8'd0};     // R1 = 0x003C = 60 = 3*B

    // ── Step 3: Spill 3B, isolate 3A as a multiple of 256 ───
    //
    //   STORE R1, [50]   → MEM[50] = 60  (spill 3B for later)
    //   SUB R0, R1       → R0 = 0x1E3C - 0x003C = 0x1E00 = 7680 = 3A*256
    memory[28] = {`OP_STORE, `REG_R1, 2'b00, 8'd50};    // MEM[50] = 60
    memory[29] = {`OP_SUB,   `REG_R0, `REG_R1, 8'd0};  // R0 = 3A*256 = 7680

    // ── Step 4: Divide R0 by 256 → R1 = 3A = 30 ─────────────
    //
    //   255 is the largest 8-bit immediate; 256 = 255+1.
    //   INC R2 (where R2=255) gives R2=256 without a wider constant.
    //
    //   Loop: subtract 256 from R0, count iterations.
    //   BEQ fires immediately after SUB (before INC) to capture
    //   the cycle where R0 hits exactly zero.
    //
    //   loop_hi [33]:
    //       SUB R0, R2       ; R0 -= 256
    //       BEQ done_hi [37] ; branch if R0 == 0
    //       INC R1           ; counter++
    //       JMP loop_hi [33]
    //   done_hi [37]:
    //       INC R1           ; count the final iteration
    //   → R1 = 30 = 3*A
    memory[30] = {`OP_LDI, `REG_R2, 2'b00, 8'd255};    // R2 = 255
    memory[31] = {`OP_INC, `REG_R2, 2'b00, 8'd0};      // R2 = 256  (INC trick)
    memory[32] = {`OP_LDI, `REG_R1, 2'b00, 8'd0};      // R1 = 0  (loop counter)

    // loop_hi: addr 33
    memory[33] = {`OP_SUB, `REG_R0, `REG_R2, 8'd0};    // R0 -= 256
    memory[34] = {`OP_BEQ, 4'b0000, 8'd37};             // if R0==0 → done_hi (37)
    memory[35] = {`OP_INC, `REG_R1, 2'b00, 8'd0};      // R1++
    memory[36] = {`OP_JMP, 4'b0000, 8'd33};             // JMP loop_hi

    // done_hi: addr 37
    memory[37] = {`OP_INC, `REG_R1, 2'b00, 8'd0};      // R1++ (final count) → R1 = 30

    // ── Step 5: Scalar sum 3A + 3B ───────────────────────────
    //
    //   LOAD R0, [50]    → R0 = 60 = 3B  (reload spilled value)
    //   ADD  R0, R1      → R0 = 60 + 30 = 90 = 3A + 3B
    memory[38] = {`OP_LOAD, `REG_R0, 2'b00, 8'd50};    // R0 = 3B = 60
    memory[39] = {`OP_ADD,  `REG_R0, `REG_R1, 8'd0};  // R0 = 90 = 3A + 3B

    // ── Step 6: Divide R0 by 2 → R1 = average = 45 ──────────
    //
    //   Same repeated-subtraction pattern, divisor=2.
    //
    //   loop_div [42]:
    //       SUB R0, R2       ; R0 -= 2
    //       BEQ done_div[46] ; branch if R0 == 0
    //       INC R1           ; quotient++
    //       JMP loop_div[42]
    //   done_div [46]:
    //       INC R1           ; count final iteration
    //   → R1 = 45
    memory[40] = {`OP_LDI, `REG_R1, 2'b00, 8'd0};     // R1 = 0  (quotient)
    memory[41] = {`OP_LDI, `REG_R2, 2'b00, 8'd2};     // R2 = 2  (divisor)

    // loop_div: addr 42
    memory[42] = {`OP_SUB, `REG_R0, `REG_R2, 8'd0};   // R0 -= 2
    memory[43] = {`OP_BEQ, 4'b0000, 8'd46};            // if R0==0 → done_div (46)
    memory[44] = {`OP_INC, `REG_R1, 2'b00, 8'd0};     // R1++
    memory[45] = {`OP_JMP, 4'b0000, 8'd42};            // JMP loop_div

    // done_div: addr 46
    memory[46] = {`OP_INC, `REG_R1, 2'b00, 8'd0};     // R1++ → R1 = 45

    // ── Epilogue: move result to R0, restore callee-saved regs ─
    memory[47] = {`OP_MOV,  `REG_R0, `REG_R1, 8'd0};  // R0 = 45  (return value)
    memory[48] = {`OP_POP,  `REG_R2, 2'b00, 8'd0};    // POP R2 ← restored, SP→FD
    memory[49] = {`OP_POP,  `REG_R1, 2'b00, 8'd0};    // POP R1 ← restored, SP→FE
    memory[50] = {`OP_JMP,  4'b0000, 8'd13};           // RETURN: JMP 13 (return site)

end

assign instruction = memory[address];

endmodule