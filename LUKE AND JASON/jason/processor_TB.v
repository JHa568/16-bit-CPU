`timescale 1ns / 1ps

// =============================================================
// processor_TB.v
// -------------------------------------------------------------
// Testbench for PUSH / POP extension.
//
// Runs the following program and checks every stage:
//   LDI R0,10 | LDI R1,20 | LDI R2,30
//   PUSH R0   | PUSH R1   | PUSH R2
//   LDI R0,0  | LDI R1,0  | LDI R2,0
//   POP R0    | POP R1    | POP R2
//   HALT
//
// Expected final state:
//   R0 = 30  R1 = 20  R2 = 10   (LIFO restored)
//   SP = 0xFF                    (fully unwound)
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
    // Instantiate processor
    // ----------------------------------------------------------
    processor_top uut (
        .clk             (clk),
        .rst             (rst),
        .halted_debug    (halted_debug),
        .state_debug     (state_debug),
        .pc_debug        (pc_debug),
        .instruction_debug(instruction_debug),
        .R0_debug        (R0_debug),
        .R1_debug        (R1_debug),
        .R2_debug        (R2_debug),
        .mem20_debug     (mem20_debug),
        .zero_flag_debug (zero_flag_debug),
        .bus_debug       (bus_debug),
        .sp_debug        (sp_debug)
    );

    // 10 ns clock
    always #5 clk = ~clk;

    // ----------------------------------------------------------
    // Cycle-by-cycle monitor
    // ----------------------------------------------------------
    initial begin
        $display("=======================================================");
        $display(" Cycle-by-cycle trace");
        $display("  t(ns) | PC | IR(hex) | R0  R1  R2 | SP   | state");
        $display("=======================================================");
        $monitor("%6t  | %2d | %h  | %3d  %3d  %3d | 0x%h | %1d",
                 $time, pc_debug, instruction_debug,
                 R0_debug, R1_debug, R2_debug,
                 sp_debug, state_debug);
    end

    // ----------------------------------------------------------
    // Main test sequence
    // ----------------------------------------------------------
    integer pass_count;
    integer fail_count;

    task check;
        input [63:0] got;
        input [63:0] expected;
        input [255:0] label;
        begin
            if (got === expected) begin
                $display("  [PASS] %s = %0d", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s : got %0d, expected %0d", label, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("final_cpu.vcd");
        $dumpvars(0, processor_TB);

        pass_count = 0;
        fail_count = 0;

        clk = 1'b0;
        rst = 1'b1;
        #20;
        rst = 1'b0;

        // --------------------------------------------------
        // Wait for HALT
        // Each instruction takes ~4 clock cycles (FETCH,
        // PC_INC, DECODE + extra states for PUSH/POP).
        // 13 instructions x 6 cycles x 10ns = ~780ns, use 2000ns
        // --------------------------------------------------
        wait (halted_debug == 1'b1);
        #20; // settle

        // --------------------------------------------------
        // Check results
        // --------------------------------------------------
        $display("");
        $display("=======================================================");
        $display(" Final register and stack checks");
        $display("=======================================================");

        check(R0_debug,  16'd30, "R0 (expect 30 — last POP is top of stack)");
        check(R1_debug,  16'd20, "R1 (expect 20)");
        check(R2_debug,  16'd10, "R2 (expect 10 — first pushed, last popped)");
        check(sp_debug,   8'hFF, "SP (expect 0xFF — fully unwound)");
        check(halted_debug, 1'b1, "halted");

        // Also verify stack memory was written correctly
        // by checking the internal data_memory array
        $display("");
        $display("  Stack memory snapshot (written during PUSH phase):");
        $display("  mem[0xFF] = %0d (expect 10)", uut.dmem.memory[8'hFF]);
        $display("  mem[0xFE] = %0d (expect 20)", uut.dmem.memory[8'hFE]);
        $display("  mem[0xFD] = %0d (expect 30)", uut.dmem.memory[8'hFD]);

        if (uut.dmem.memory[8'hFF] == 16'd10 &&
            uut.dmem.memory[8'hFE] == 16'd20 &&
            uut.dmem.memory[8'hFD] == 16'd30) begin
            $display("  [PASS] Stack memory contents correct");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Stack memory contents wrong");
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------
        // Summary
        // --------------------------------------------------
        $display("");
        $display("=======================================================");
        $display(" RESULT: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display(" ALL TESTS PASSED");
        else
            $display(" SOME TESTS FAILED");
        $display("=======================================================");

        $finish;
    end

endmodule
