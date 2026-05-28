`timescale 1ns / 1ps

// =============================================================
// processor_TB.v  —  Tiny OS testbench
// =============================================================
// Runs the round-robin OS program and verifies all final state:
//
//   MEM[1] = 15  os_tick      (15 scheduler calls)
//   MEM[2] = 15  task0.sum    (1+2+3+4+5)
//   MEM[3] =  6  task0.addend
//   MEM[4] = 32  task1.value  (1 × 2^5)
//   MEM[5] =  0  task2.count  (exhausted)
//   halted =  1
// =============================================================

module processor_TB;

    // ----------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------
    reg  clk, rst;

    wire        halted_debug;
    wire [3:0]  state_debug;
    wire [7:0]  pc_debug;
    wire [15:0] instruction_debug;
    wire [15:0] R0_debug, R1_debug, R2_debug;
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
    // Pass / fail counters
    // ----------------------------------------------------------
    integer pass_count, fail_count;

    task check;
        input [63:0]  got;
        input [63:0]  expected;
        input [255:0] label;
        begin
            if (got === expected) begin
                $display("  [PASS] %-40s = %0d (0x%h)", label, got, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %-40s : got %0d (0x%h), expected %0d (0x%h)",
                         label, got, got, expected, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------
    // Cycle trace
    // ----------------------------------------------------------
    initial begin
        $display("=============================================================");
        $display("  Tiny OS trace");
        $display("  time  | PC | IR(hex) | R0   R1   R2 | zf | st");
        $display("=============================================================");
        $monitor("%6t | %2d | %h  | %5d %5d %5d | %0b  | %0d",
                 $time, pc_debug, instruction_debug,
                 R0_debug, R1_debug, R2_debug,
                 zero_flag_debug, state_debug);
    end

    // ----------------------------------------------------------
    // Timeout watchdog (separate initial block)
    // ----------------------------------------------------------
    initial begin
        #50000;
        $display("");
        $display("[TIMEOUT] CPU did not halt within 50000 ns.");
        $finish;
    end

    // ----------------------------------------------------------
    // Main test
    // ----------------------------------------------------------
    initial begin
        $dumpfile("os_tb.vcd");
        $dumpvars(0, processor_TB);

        pass_count = 0;
        fail_count = 0;

        clk = 1'b0;
        rst = 1'b1;
        #20;
        #20;
        rst = 1'b0;

        // --------------------------------------------------
        // Wait for HALT (Task2 countdown reaches 0)
        // Worst-case: 5 rounds × 3 tasks × ~10 cycles × 10ns
        //             = ~1500 ns, well inside the watchdog
        // --------------------------------------------------
        wait (halted_debug == 1'b1);
        #20; // let last write fully settle

        // --------------------------------------------------
        // Final state checks
        // --------------------------------------------------
        $display("");
        $display("=============================================================");
        $display("  Final state after HALT");
        $display("=============================================================");

        check(halted_debug,             1,    "halted");

        check(uut.dmem.memory[1], 16'd15,
              "MEM[1] os_tick           (expect 15)");

        check(uut.dmem.memory[2], 16'd15,
              "MEM[2] task0.sum         (expect 15 = 1+2+3+4+5)");

        check(uut.dmem.memory[3], 16'd6,
              "MEM[3] task0.addend      (expect 6)");

        check(uut.dmem.memory[4], 16'd32,
              "MEM[4] task1.value       (expect 32 = 2^5)");

        check(uut.dmem.memory[5], 16'd0,
              "MEM[5] task2.countdown   (expect 0)");

        check(sp_debug, 8'hFF,
              "SP unchanged             (expect 0xFF)");

        // --------------------------------------------------
        // Human-readable memory snapshot
        // --------------------------------------------------
        $display("");
        $display("  OS data memory snapshot:");
        $display("    MEM[0] current_task = %0d", uut.dmem.memory[0]);
        $display("    MEM[1] os_tick      = %0d", uut.dmem.memory[1]);
        $display("    MEM[2] task0.sum    = %0d", uut.dmem.memory[2]);
        $display("    MEM[3] task0.addend = %0d", uut.dmem.memory[3]);
        $display("    MEM[4] task1.value  = %0d", uut.dmem.memory[4]);
        $display("    MEM[5] task2.count  = %0d", uut.dmem.memory[5]);

        // --------------------------------------------------
        // Summary
        // ======================================================
        $display("");
        $display("=============================================================");
        $display("  RESULT: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED");
        $display("=============================================================");

        $finish;
    end

endmodule