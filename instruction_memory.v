`timescale 1ns / 1ps
`include "constants.v"

// =============================================================
// instruction_memory.v  —  Tiny Round-Robin OS Demo
// =============================================================
//
// OVERVIEW
// ─────────────────────────────────────────────────────────────
// A minimal cooperative multitasking OS on a 3-register ISA.
// The kernel consists of:
//
//   1. KERNEL INIT   — clears and seeds all OS data in memory,
//                      seeds current_task = 2 so the very first
//                      scheduler dispatch wraps to Task 0.
//
//   2. SCHEDULER     — round-robin, mod-3, cooperative.
//                      Each call increments os_tick, advances
//                      current_task, then dispatches.  Tasks
//                      "yield" simply by jumping back here.
//                      Dispatch uses two tricks that work with
//                      only 3 registers and no indirect jump:
//                        XOR Rx,R2(=0) → zero_flag if Rx==0
//                        SUB Rx,R2(=1) → zero_flag if Rx==1
//
//   3. TASK 0        — Accumulator:  sum += addend; addend++
//   4. TASK 1        — Doubler:      value *= 2
//   5. TASK 2        — Countdown:    count--; HALT when count==0
//
// DATA MEMORY MAP
// ─────────────────────────────────────────────────────────────
//   MEM[0] = current_task_id    (0 | 1 | 2)
//   MEM[1] = os_tick            (scheduler call counter)
//   MEM[2] = task0_sum          (running accumulator)
//   MEM[3] = task0_addend       (grows: 1→2→3→4→5→6)
//   MEM[4] = task1_value        (powers-of-2: 1→2→4→8→16→32)
//   MEM[5] = task2_countdown    (5→4→3→2→1→0 → HALT)
//
// INSTRUCTION MEMORY MAP
// ─────────────────────────────────────────────────────────────
//   [  0 – 10 ]  Kernel init
//   [ 11 – 31 ]  Scheduler
//   [ 32 – 38 ]  Task 0: Accumulator
//   [ 39 – 42 ]  Task 1: Doubler
//   [ 43 – 50 ]  Task 2: Countdown → HALT
//
// EXPECTED FINAL STATE  (verified by processor_TB.v)
// ─────────────────────────────────────────────────────────────
//   MEM[1] = 15   os_tick      (15 scheduler calls: 5 rounds × 3)
//   MEM[2] = 15   task0.sum    (1+2+3+4+5)
//   MEM[3] =  6   task0.addend (next value after 5th run)
//   MEM[4] = 32   task1.value  (1 × 2^5)
//   MEM[5] =  0   task2.count  (exhausted)
//   halted =  1
// =============================================================

module instruction_memory(
    input  [7:0]  address,
    output [15:0] instruction
);

    reg [15:0] memory [255:0];

    // ----------------------------------------------------------
    // Jump / branch target addresses
    // ----------------------------------------------------------
    localparam [7:0] SCHED   = 8'd11;   // Scheduler entry
    localparam [7:0] TASK0   = 8'd32;   // Task 0 entry
    localparam [7:0] TASK1   = 8'd39;   // Task 1 entry
    localparam [7:0] TASK2   = 8'd43;   // Task 2 entry
    localparam [7:0] SYS_HALT = 8'd50;  // HALT instruction

    initial begin
    initial begin

        // ======================================================
        // KERNEL INIT  [0 – 10]
        // ======================================================
        // Zero os_tick and task0.sum
        memory[0]  = {`OP_LDI,   `REG_R0, 2'b00, 8'd0};    // R0 = 0
        memory[1]  = {`OP_STORE, `REG_R0, 2'b00, 8'd1};    // MEM[1] = 0   (os_tick)
        memory[2]  = {`OP_STORE, `REG_R0, 2'b00, 8'd2};    // MEM[2] = 0   (task0.sum)

        // Seed task0.addend = 1, task1.value = 1
        memory[3]  = {`OP_LDI,   `REG_R0, 2'b00, 8'd1};    // R0 = 1
        memory[4]  = {`OP_STORE, `REG_R0, 2'b00, 8'd3};    // MEM[3] = 1   (task0.addend)
        memory[5]  = {`OP_STORE, `REG_R0, 2'b00, 8'd4};    // MEM[4] = 1   (task1.value)

        // Seed task2.countdown = 5
        memory[6]  = {`OP_LDI,   `REG_R0, 2'b00, 8'd5};    // R0 = 5
        memory[7]  = {`OP_STORE, `REG_R0, 2'b00, 8'd5};    // MEM[5] = 5   (task2.countdown)

        // current_task = 2  (so first scheduler call wraps → dispatches Task 0)
        memory[8]  = {`OP_LDI,   `REG_R0, 2'b00, 8'd2};    // R0 = 2
        memory[9]  = {`OP_STORE, `REG_R0, 2'b00, 8'd0};    // MEM[0] = 2   (current_task)

        // Enter the scheduler
        memory[10] = {`OP_JMP,   2'b00,   2'b00, SCHED};   // JMP SCHED

        // ======================================================
        // SCHEDULER  [11 – 31]
        // ======================================================
        // Entered via JMP from kernel init or task yield.
        // R1 will hold next_task throughout this block.
        //
        //  Step 1: R1 = MEM[0]              (load current_task)
        //  Step 2: os_tick++                 (bookkeeping)
        //  Step 3: R1 = (R1 + 1) % 3        (advance to next task)
        //  Step 4: MEM[0] = R1              (save next_task)
        //  Step 5: dispatch                  (chain of BEQ / JMP)
        //
        // Dispatch trick (no indirect jump available):
        //   Copy R1 into R0, load R2=0, XOR R0,R2
        //     → R0 unchanged; zero_flag set iff next_task == 0
        //   Restore R0=R1, load R2=1, SUB R0,R2
        //     → zero_flag set iff next_task == 1
        //   Else fall through to JMP TASK2
        // ======================================================

        // --- load current_task ---
        memory[11] = {`OP_LOAD,  `REG_R1, 2'b00, 8'd0};    // R1 = MEM[0]  (current_task)

        // --- bump os_tick ---
        memory[12] = {`OP_LOAD,  `REG_R0, 2'b00, 8'd1};    // R0 = MEM[1]  (os_tick)
        memory[13] = {`OP_INC,   `REG_R0, 2'b00, 8'd0};    // R0 = R0 + 1
        memory[14] = {`OP_STORE, `REG_R0, 2'b00, 8'd1};    // MEM[1] = R0

        // --- next_task = (current_task + 1) % 3 ---
        // R1 = R1 + 1; then if R1 == 3 wrap to 0
        memory[15] = {`OP_LDI,   `REG_R0, 2'b00, 8'd1};    // R0 = 1
        memory[16] = {`OP_ADD,   `REG_R1, `REG_R0, 8'd0};  // R1 = R1 + 1
        memory[17] = {`OP_LDI,   `REG_R0, 2'b00, 8'd3};    // R0 = 3
        memory[18] = {`OP_SUB,   `REG_R0, `REG_R1, 8'd0};  // R0 = 3 – R1; zero ↔ R1==3
        memory[19] = {`OP_BEQ,   2'b00,   2'b00, 8'd21};   // if zero → wrap → [21]
        memory[20] = {`OP_JMP,   2'b00,   2'b00, 8'd22};   // no wrap  → store  → [22]
        memory[21] = {`OP_LDI,   `REG_R1, 2'b00, 8'd0};    // wrap: R1 = 0

        // --- save next_task ---
        memory[22] = {`OP_STORE, `REG_R1, 2'b00, 8'd0};    // MEM[0] = R1  (next_task)

        // --- dispatch: check task 0 ---
        // XOR R0 with 0: R0 unchanged; zero_flag set iff R0 (== next_task) == 0
        memory[23] = {`OP_MOV,   `REG_R0, `REG_R1, 8'd0};  // R0 = R1  (next_task)
        memory[24] = {`OP_LDI,   `REG_R2, 2'b00, 8'd0};    // R2 = 0
        memory[25] = {`OP_XOR,   `REG_R0, `REG_R2, 8'd0};  // R0^=0; zero_flag ↔ task==0
        memory[26] = {`OP_BEQ,   2'b00,   2'b00, TASK0};   // → Task 0

        // --- dispatch: check task 1 ---
        // Restore R0 from R1 (R1 unchanged since [22]), subtract 1
        memory[27] = {`OP_MOV,   `REG_R0, `REG_R1, 8'd0};  // R0 = R1  (restore)
        memory[28] = {`OP_LDI,   `REG_R2, 2'b00, 8'd1};    // R2 = 1
        memory[29] = {`OP_SUB,   `REG_R0, `REG_R2, 8'd0};  // R0 = R0–1; zero ↔ task==1
        memory[30] = {`OP_BEQ,   2'b00,   2'b00, TASK1};   // → Task 1

        // --- dispatch: task 2 (only remaining case) ---
        memory[31] = {`OP_JMP,   2'b00,   2'b00, TASK2};   // → Task 2

        // ======================================================
        // TASK 0: Accumulator  [32 – 38]
        // ======================================================
        // Each run: sum += addend, then addend++
        //
        // Run 1: sum = 0+1 = 1,  addend → 2
        // Run 2: sum = 1+2 = 3,  addend → 3
        // Run 3: sum = 3+3 = 6,  addend → 4
        // Run 4: sum = 6+4 = 10, addend → 5
        // Run 5: sum =10+5 = 15, addend → 6   ← final
        // ======================================================
        memory[32] = {`OP_LOAD,  `REG_R0, 2'b00, 8'd2};    // R0 = MEM[2]  (sum)
        memory[33] = {`OP_LOAD,  `REG_R1, 2'b00, 8'd3};    // R1 = MEM[3]  (addend)
        memory[34] = {`OP_ADD,   `REG_R0, `REG_R1, 8'd0};  // R0 = sum + addend
        memory[35] = {`OP_STORE, `REG_R0, 2'b00, 8'd2};    // MEM[2] = new sum
        memory[36] = {`OP_INC,   `REG_R1, 2'b00, 8'd0};    // R1 = addend + 1
        memory[37] = {`OP_STORE, `REG_R1, 2'b00, 8'd3};    // MEM[3] = new addend
        memory[38] = {`OP_JMP,   2'b00,   2'b00, SCHED};   // yield → scheduler

        // ======================================================
        // TASK 1: Doubler  [39 – 42]
        // ======================================================
        // Each run: value = value * 2  (ADD Rx, Rx shifts left by 1)
        //
        // Run 1:  1 →  2
        // Run 2:  2 →  4
        // Run 3:  4 →  8
        // Run 4:  8 → 16
        // Run 5: 16 → 32   ← final
        // ======================================================
        memory[39] = {`OP_LOAD,  `REG_R0, 2'b00, 8'd4};    // R0 = MEM[4]  (value)
        memory[40] = {`OP_ADD,   `REG_R0, `REG_R0, 8'd0};  // R0 = R0 * 2
        memory[41] = {`OP_STORE, `REG_R0, 2'b00, 8'd4};    // MEM[4] = new value
        memory[42] = {`OP_JMP,   2'b00,   2'b00, SCHED};   // yield → scheduler

        // ======================================================
        // TASK 2: Countdown → HALT  [43 – 50]
        // ======================================================
        // Each run: countdown--
        // When countdown reaches 0, BEQ fires → HALT.
        // If not, yield back to scheduler.
        //
        // Run 1: 5 → 4  (yield)
        // Run 2: 4 → 3  (yield)
        // Run 3: 3 → 2  (yield)
        // Run 4: 2 → 1  (yield)
        // Run 5: 1 → 0  → BEQ → HALT  (no yield)
        // ======================================================
        memory[43] = {`OP_LOAD,  `REG_R0, 2'b00, 8'd5};    // R0 = MEM[5]  (countdown)
        memory[44] = {`OP_LDI,   `REG_R1, 2'b00, 8'd1};    // R1 = 1
        memory[45] = {`OP_SUB,   `REG_R0, `REG_R1, 8'd0};  // R0 = countdown – 1
        memory[46] = {`OP_STORE, `REG_R0, 2'b00, 8'd5};    // MEM[5] = new countdown
        memory[47] = {`OP_BEQ,   2'b00,   2'b00, SYS_HALT};// zero_flag → countdown==0 → HALT
        memory[48] = {`OP_JMP,   2'b00,   2'b00, SCHED};   // yield → scheduler
        memory[49] = {`OP_JMP,   2'b00,   2'b00, SYS_HALT};// (safety, never reached)

        // ======================================================
        // SYSTEM HALT  [50]
        // ======================================================
        memory[50] = {`OP_HALT,  12'd0};                    // ── HALT ──

    end
    end

    assign instruction = memory[address];
    assign instruction = memory[address];

endmodule