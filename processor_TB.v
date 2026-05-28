`timescale 1ns / 1ps

// =============================================================
// processor_TB.v — SIMD Average Function Demo Testbench
// -------------------------------------------------------------
// Tests the simd_avg program in instruction_memory.v.
//
// Program summary:
//   MAIN builds R0 = {A=10, B=20} = 0x0A14
//   Calls simd_avg which:
//     1. SIMD ×3 multiplies both lanes:    R0 → 0x1E3C = {30,60}
//     2. AND-masks lo lane:                R1  = 60 = 3B
//     3. SUB+÷256 loop extracts hi lane:  R1  = 30 = 3A
//     4. Scalar sums:                      R0  = 90 = 3A+3B
//     5. ÷2 loop computes average:         R1  = 45
//     6. Returns R0 = 45
//   Return site pops original input into R1, then HALTs.
//
// EXPECTED FINAL STATE (verified by simulation)
// ──────────────────────────────────────────────
//   R0 = 45          (average result)
//   R1 = 0x0A14      (original packed input, restored from stack)
//   R2 = 0           (callee-saved, fully restored)
//   SP = 0xFF        (fully unwound — 3 push, 3 pop)
//   MEM[50] = 60     (spill slot: 3*B, written inside function)
//   MEM[0xFF] = 0x0A14  (caller push of R0)
//   MEM[0xFE] = 20      (callee push of R1 — R1 was 20 at call site)
//   MEM[0xFD] = 0       (callee push of R2 — R2 was  0 at call site)
//   halted = 1
// =============================================================

module processor_TB;

    // ----------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------
    reg  clk;
    reg  rst;

    wire        halted_debug;
    wire [3:0]  state_debug;
    wire [7:0]  pc_debug;
    wire [15:0] instruction_debug;
    wire [15:0] R0_debug;
    wire [15:0] R1_debug;
    wire [15:0] R2_debug;
    wire [15:0] mem20_debug;
    wire        zero_flag_debug;
    wire [15:0] bus_debug;
    wire [7:0]  sp_debug;

    // ----------------------------------------------------------
    // DUT
    // ----------------------------------------------------------
    processor_top uut (
        .clk              (clk),
        .rst              (rst),
        .halted_debug     (halted_debug),
        .state_debug      (state_debug),
        .pc_debug         (pc_debug),
        .instruction_debug(instruction_debug),
        .R0_debug         (R0_debug),
        .R1_debug         (R1_debug),
        .R2_debug         (R2_debug),
        .mem20_debug      (mem20_debug),
        .zero_flag_debug  (zero_flag_debug),
        .bus_debug        (bus_debug),
        .sp_debug         (sp_debug)
    );

    // 10 ns clock (100 MHz)
    always #5 clk = ~clk;

    // ----------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // Wait for the current instruction to fully complete —
    // defined as the moment the FSM returns to S_FETCH (state 0).
    // A small #1 delay after the wait lets register writes settle.
    task wait_for_next_fetch;
        begin
            wait (state_debug != 4'd0);   // leave current FETCH
            wait (state_debug == 4'd0);   // arrive at next FETCH
            #1;
        end
    endtask

    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [255:0] label;
        begin
            if (got === expected) begin
                $display("  [PASS] %-40s got %0d (0x%04h)", label, got, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %-40s got %0d (0x%04h), expected %0d (0x%04h)",
                         label, got, got, expected, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check8;
        input [7:0] got;
        input [7:0] expected;
        input [255:0] label;
        begin
            if (got === expected) begin
                $display("  [PASS] %-40s got 0x%02h", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %-40s got 0x%02h, expected 0x%02h",
                         label, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check1;
        input got;
        input expected;
        input [255:0] label;
        begin
            if (got === expected) begin
                $display("  [PASS] %-40s got %0d", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %-40s got %0d, expected %0d",
                         label, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------
    // Cycle monitor
    // ----------------------------------------------------------
    initial begin
        $display("=========================================================");
        $display(" Cycle trace");
        $display("  t(ns) | PC | IR(hex) | R0    R1    R2   | SP   | st");
        $display("=========================================================");
        // $monitor("%6t | %2d | %h  | %5d %5d %5d | 0x%h | %1d",
        //          $time, pc_debug, instruction_debug,
        //          R0_debug, R1_debug, R2_debug,
        //          sp_debug, state_debug);
    end

    // ----------------------------------------------------------
    // Main test sequence
    // ----------------------------------------------------------
    initial begin
        $dumpfile("final_cpu.vcd");
        $dumpvars(0, processor_TB);

        pass_count = 0;
        fail_count = 0;

        clk = 1'b0;
        rst = 1'b1;
        #20;
        rst = 1'b0;

        // ======================================================
        // PHASE 1 — MAIN: Build R0 = {A=10, B=20} = 0x0A14
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 1 — Build packed input R0 = 0x0A14");
        $display("=========================================================");

        // [0]  LDI R0, 10
        wait_for_next_fetch();
        check16(R0_debug, 16'd10, "[0]  LDI R0, 10 → R0=10");

        // [1]  ADD R0, R0 → 20
        wait_for_next_fetch();
        check16(R0_debug, 16'd20, "[1]  ADD R0,R0  → R0=20");

        // [2]  ADD → 40
        wait_for_next_fetch();
        check16(R0_debug, 16'd40, "[2]  ADD R0,R0  → R0=40");

        // [3]  ADD → 80
        wait_for_next_fetch();
        check16(R0_debug, 16'd80, "[3]  ADD R0,R0  → R0=80");

        // [4]  ADD → 160
        wait_for_next_fetch();
        check16(R0_debug, 16'd160, "[4]  ADD R0,R0  → R0=160");

        // [5]  ADD → 320
        wait_for_next_fetch();
        check16(R0_debug, 16'd320, "[5]  ADD R0,R0  → R0=320");

        // [6]  ADD → 640
        wait_for_next_fetch();
        check16(R0_debug, 16'd640, "[6]  ADD R0,R0  → R0=640");

        // [7]  ADD → 1280
        wait_for_next_fetch();
        check16(R0_debug, 16'd1280, "[7]  ADD R0,R0  → R0=1280");

        // [8]  ADD → 2560 = 0x0A00
        wait_for_next_fetch();
        check16(R0_debug, 16'h0A00, "[8]  ADD R0,R0  → R0=0x0A00 (A<<8)");

        // [9]  LDI R1, 20
        wait_for_next_fetch();
        check16(R1_debug, 16'd20, "[9]  LDI R1,20  → R1=20");

        // [10] OR R0, R1 → 0x0A14
        wait_for_next_fetch();
        check16(R0_debug, 16'h0A14, "[10] OR R0,R1   → R0=0x0A14 {A=10,B=20}");

        // ======================================================
        // PHASE 2 — CALL: PUSH R0, JMP 20
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 2 — Call setup: PUSH input, JMP to function");
        $display("=========================================================");

        // [11] PUSH R0 → MEM[FF]=0x0A14, SP→0xFE
        wait_for_next_fetch();
        check8 (sp_debug,  8'hFE,    "[11] PUSH R0    → SP=0xFE");

        // [12] JMP 20 — verify PC jumps to function (SP/regs unchanged)
        wait_for_next_fetch();
        check8 (sp_debug,  8'hFE,    "[12] JMP 20     → SP still 0xFE");

        // ======================================================
        // PHASE 3 — FUNCTION ENTRY: callee-save R1, R2
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 3 — Function entry: callee-save R1 and R2");
        $display("=========================================================");

        // [20] PUSH R1 (R1=20 at this point) → SP→0xFD
        wait_for_next_fetch();
        check8 (sp_debug,  8'hFD,    "[20] PUSH R1    → SP=0xFD");

        // [21] PUSH R2 (R2=0 at this point) → SP→0xFC
        wait_for_next_fetch();
        check8 (sp_debug,  8'hFC,    "[21] PUSH R2    → SP=0xFC");

        // ======================================================
        // PHASE 4 — SIMD ×3 MULTIPLY (both lanes in parallel)
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 4 — SIMD 2x8 multiply both lanes by 3");
        $display("=========================================================");

        // [22] MOV R1, R0 → R1 = 0x0A14
        wait_for_next_fetch();
        check16(R1_debug, 16'h0A14, "[22] MOV R1,R0  → R1=0x0A14 {A,B}");

        // [23] SIMD ADD 2x8 R0,R0 → R0={2A,2B}=0x1428
        // hi: 0x0A+0x0A=0x14, lo: 0x14+0x14=0x28
        wait_for_next_fetch();
        check16(R0_debug, 16'h1428, "[23] SIMD ADD R0,R0 → R0=0x1428 {2A,2B}");

        // [24] SIMD ADD 2x8 R0,R1 → R0={3A,3B}=0x1E3C
        // hi: 0x14+0x0A=0x1E=30, lo: 0x28+0x14=0x3C=60
        wait_for_next_fetch();
        check16(R0_debug, 16'h1E3C, "[24] SIMD ADD R0,R1 → R0=0x1E3C {30,60}");

        // ======================================================
        // PHASE 5 — UNPACK LO LANE via AND mask
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 5 — Unpack lo lane (3B=60) via AND 0x00FF mask");
        $display("=========================================================");

        // [25] LDI R2, 0xFF
        wait_for_next_fetch();
        check16(R2_debug, 16'h00FF, "[25] LDI R2,0xFF → R2=0x00FF");

        // [26] MOV R1, R0 → R1 = 0x1E3C
        wait_for_next_fetch();
        check16(R1_debug, 16'h1E3C, "[26] MOV R1,R0   → R1=0x1E3C");

        // [27] AND R1, R2 → R1 = 0x003C = 60
        wait_for_next_fetch();
        check16(R1_debug, 16'h003C, "[27] AND R1,R2   → R1=0x003C (3B=60)");

        // ======================================================
        // PHASE 6 — SPILL 3B and ISOLATE hi lane × 256
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 6 — Spill 3B to MEM[50], isolate 3A*256");
        $display("=========================================================");

        // [28] STORE R1, [50] → MEM[50] = 60
        wait_for_next_fetch();
        // mem20_debug only shows MEM[20] so we verify indirectly after LOAD
        // Check SP unchanged (no stack op)
        check8 (sp_debug, 8'hFC,    "[28] STORE R1,[50] → SP unchanged 0xFC");

        // [29] SUB R0, R1 → R0 = 0x1E3C - 0x003C = 0x1E00 = 7680
        wait_for_next_fetch();
        check16(R0_debug, 16'h1E00, "[29] SUB R0,R1   → R0=0x1E00 (3A*256=7680)");

        // ======================================================
        // PHASE 7 — DIVIDE by 256 LOOP (extracts hi lane = 3A = 30)
        //
        // Setup: LDI R2,255  INC R2→256  LDI R1,0
        // Loop (30 iterations): SUB R0,R2; BEQ done_hi; INC R1; JMP
        // done_hi [37]: INC R1 → R1 = 30
        //
        // FIX: gate the wait on state_debug==FETCH (4'd0) so that the
        // transient pc_debug==37 driven during BEQ EXECUTE (when the
        // branch is NOT yet taken) does not trigger a false early exit.
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 7 — Divide by 256 loop → R1 = 3A = 30");
        $display("=========================================================");

        // [30] LDI R2, 255
        wait_for_next_fetch();
        check16(R2_debug, 16'd255,  "[30] LDI R2,255  → R2=255");

        // [31] INC R2 → 256
        wait_for_next_fetch();
        check16(R2_debug, 16'd256,  "[31] INC R2      → R2=256");

        // [32] LDI R1, 0 (counter)
        wait_for_next_fetch();
        check16(R1_debug, 16'd0,    "[32] LDI R1,0    → R1=0 (counter)");

        // Loop runs 30 times through [33][34][35][36], then exits via BEQ→[37].
        // Wait until PC=37 AND state=FETCH — this filters out the transient
        // pc_debug=37 that the FSM drives during BEQ EXECUTE before the
        // zero-flag check gates it, which previously caused a false early exit
        // after only one loop iteration.
        $display("  ... waiting for divide-by-256 loop (30 iterations) ...");
        wait (pc_debug == 8'd37 && state_debug == 4'd0);
        wait_for_next_fetch();   // let [37] INC R1 complete before sampling
        check16(R0_debug, 16'd0,    "[37] done_hi: R0=0 (fully divided)");
        check16(R1_debug, 16'd30,   "[37] done_hi: R1=30 (= 3*A = 3*10)");

        // ======================================================
        // PHASE 8 — SCALAR SUM: 3A + 3B = 90
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 8 — Scalar sum 3A + 3B = 90");
        $display("=========================================================");

        // [38] LOAD R0, [50] → R0 = 60 (3B reloaded from spill)
        wait_for_next_fetch();
        check16(R0_debug, 16'd60,   "[38] LOAD R0,[50] → R0=60 (3B from spill)");

        // [39] ADD R0, R1 → R0 = 60+30 = 90
        wait_for_next_fetch();
        check16(R0_debug, 16'd90,   "[39] ADD R0,R1   → R0=90 (3A+3B)");

        // ======================================================
        // PHASE 9 — DIVIDE by 2 LOOP (= average = 45)
        //
        // Setup: LDI R1,0  LDI R2,2
        // Loop (45 iterations): SUB R0,R2; BEQ done_div; INC R1; JMP
        // done_div [46]: INC R1 → R1 = 45
        //
        // FIX: same BEQ transient-PC issue as Phase 7 — gate on
        // state_debug==FETCH so we only trigger on the real fetch of [46].
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 9 — Divide by 2 loop → R1 = average = 45");
        $display("=========================================================");

        // [40] LDI R1, 0
        wait_for_next_fetch();
        check16(R1_debug, 16'd0,    "[40] LDI R1,0    → R1=0 (quotient)");

        // [41] LDI R2, 2
        wait_for_next_fetch();
        check16(R2_debug, 16'd2,    "[41] LDI R2,2    → R2=2 (divisor)");

        // Wait for done_div [46], gated on FETCH state for the same reason.
        $display("  ... waiting for divide-by-2 loop (45 iterations) ...");
        wait (pc_debug == 8'd46 && state_debug == 4'd0);
        wait_for_next_fetch();   // let [46] INC R1 complete before sampling
        check16(R0_debug, 16'd0,    "[46] done_div: R0=0 (fully divided)");
        check16(R1_debug, 16'd45,   "[46] done_div: R1=45 (average)");

        // ======================================================
        // PHASE 10 — EPILOGUE: move result, callee-restore, return
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 10 — Epilogue: result → R0, restore regs, return");
        $display("=========================================================");

        // [47] MOV R0, R1 → R0 = 45
        wait_for_next_fetch();
        check16(R0_debug, 16'd45,   "[47] MOV R0,R1   → R0=45 (result)");

        // [48] POP R2 → R2 restored to 0 (what it was when saved), SP→0xFD
        wait_for_next_fetch();
        check16(R2_debug, 16'd0,    "[48] POP R2      → R2=0 (restored)");
        check8 (sp_debug, 8'hFD,    "[48] POP R2      → SP=0xFD");

        // [49] POP R1 → R1 restored to 20 (what it was when saved), SP→0xFE
        wait_for_next_fetch();
        check16(R1_debug, 16'd20,   "[49] POP R1      → R1=20 (restored)");
        check8 (sp_debug, 8'hFE,    "[49] POP R1      → SP=0xFE");

        // [50] JMP 13 → return (no register change)
        wait_for_next_fetch();
        check16(R0_debug, 16'd45,   "[50] JMP 13      → R0 still 45");

        // ======================================================
        // PHASE 11 — RETURN SITE
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 11 — Return site: POP original input, HALT");
        $display("=========================================================");

        // [13] POP R1 ← original R0=0x0A14 pushed before call, SP→0xFF
        wait_for_next_fetch();
        check16(R1_debug, 16'h0A14, "[13] POP R1      → R1=0x0A14 (original input)");
        check8 (sp_debug, 8'hFF,    "[13] POP R1      → SP=0xFF (fully unwound)");

        // [14] HALT
        wait (halted_debug == 1'b1);
        #10;

        // ======================================================
        // PHASE 12 — FINAL STATE CHECKS
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" Phase 12 — Final state verification");
        $display("=========================================================");

        check16(R0_debug,  16'd45,   "FINAL R0 = 45 (average result)");
        check16(R1_debug,  16'h0A14, "FINAL R1 = 0x0A14 (original input restored)");
        check16(R2_debug,  16'd0,    "FINAL R2 = 0 (callee-saved, fully restored)");
        check8 (sp_debug,  8'hFF,    "FINAL SP = 0xFF (fully unwound)");
        check1 (halted_debug, 1'b1,  "FINAL halted = 1");

        // Stack memory contents (written during PUSH phase)
        $display("");
        $display("  Stack memory snapshot:");
        $display("    MEM[0xFF] = 0x%04h  (expect 0x0A14 — caller pushed R0)",
                 uut.dmem.memory[8'hFF]);
        $display("    MEM[0xFE] = %0d      (expect 20 — callee saved R1)",
                 uut.dmem.memory[8'hFE]);
        $display("    MEM[0xFD] = %0d       (expect 0  — callee saved R2)",
                 uut.dmem.memory[8'hFD]);
        $display("    MEM[50]   = %0d      (expect 60 — 3B spill slot)",
                 uut.dmem.memory[8'd50]);

        if (uut.dmem.memory[8'hFF] == 16'h0A14) begin
            $display("  [PASS] MEM[0xFF] = 0x0A14");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] MEM[0xFF]: got 0x%04h, expected 0x0A14",
                     uut.dmem.memory[8'hFF]);
            fail_count = fail_count + 1;
        end

        if (uut.dmem.memory[8'hFE] == 16'd20) begin
            $display("  [PASS] MEM[0xFE] = 20");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] MEM[0xFE]: got %0d, expected 20",
                     uut.dmem.memory[8'hFE]);
            fail_count = fail_count + 1;
        end

        if (uut.dmem.memory[8'hFD] == 16'd0) begin
            $display("  [PASS] MEM[0xFD] = 0");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] MEM[0xFD]: got %0d, expected 0",
                     uut.dmem.memory[8'hFD]);
            fail_count = fail_count + 1;
        end

        if (uut.dmem.memory[8'd50] == 16'd60) begin
            $display("  [PASS] MEM[50] = 60 (3B spill slot)");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] MEM[50]: got %0d, expected 60",
                     uut.dmem.memory[8'd50]);
            fail_count = fail_count + 1;
        end

        // ======================================================
        // Summary
        // ======================================================
        $display("");
        $display("=========================================================");
        $display(" RESULT: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display(" ALL TESTS PASSED");
        else
            $display(" SOME TESTS FAILED — check trace above");
        $display("=========================================================");

        $finish;
    end

endmodule