`timescale 1ns / 1ps

// =============================================================
// processor_TB.v
// -------------------------------------------------------------
// Simulation testbench for the final extension CPU.
//
// Unlike the essential version, this testbench does NOT manually
// feed instructions. The CPU fetches instructions from instruction
// memory using the PC.
// =============================================================

module processor_TB;

    reg clk;
    reg rst;

    wire halted_debug;
    wire [3:0]  state_debug;
    wire [7:0]  pc_debug;
    wire [15:0] instruction_debug;
    wire [15:0] R0_debug;
    wire [15:0] R1_debug;
    wire [15:0] R2_debug;
    wire [15:0] mem20_debug;
    wire zero_flag_debug;
    wire [15:0] bus_debug;

    processor_top uut(
        .clk(clk),
        .rst(rst),
        .halted_debug(halted_debug),
        .state_debug(state_debug),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .R0_debug(R0_debug),
        .R1_debug(R1_debug),
        .R2_debug(R2_debug),
        .mem20_debug(mem20_debug),
        .zero_flag_debug(zero_flag_debug),
        .bus_debug(bus_debug)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    initial begin
        $dumpfile("final_cpu.vcd");
        $dumpvars(0, processor_TB);

        clk = 1'b0;
        rst = 1'b1;

        #20;
        rst = 1'b0;

        // Run long enough for the program to reach HALT.
        #1000;

        $display("Final R0 = %h", R0_debug);
        $display("Final R1 = %h", R1_debug);
        $display("Final R2 = %h", R2_debug);
        $display("Final MEM[20] = %h", mem20_debug);
        $display("Final zero_flag = %b", zero_flag_debug);
        $display("Final PC = %h", pc_debug);
        $display("Halted = %b", halted_debug);

        if (R0_debug == 16'd0 &&
            R1_debug == 16'd7 &&
            R2_debug == 16'd9 &&
            mem20_debug == 16'd7 &&
            zero_flag_debug == 1'b1 &&
            halted_debug == 1'b1) begin
            $display("[PASS] Extension CPU program completed correctly.");
        end
        else begin
            $display("[FAIL] Extension CPU final values are not expected.");
        end

        $finish;
    end

endmodule
