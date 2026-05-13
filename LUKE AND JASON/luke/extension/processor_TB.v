`timescale 1ns / 1ps

module processor_TB;

    reg clk;
    reg rst;

    wire done;
    wire [7:0] pc_debug;
    wire [15:0] instruction_debug;
    wire [15:0] R0_debug;
    wire [15:0] R1_debug;
    wire [15:0] R2_debug;

    processor_top uut(
        .clk(clk),
        .rst(rst),
        .done(done),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .R0_debug(R0_debug),
        .R1_debug(R1_debug),
        .R2_debug(R2_debug)
    );

    // Clock: 10ns period
    always #5 clk = ~clk;

    initial begin
        $dumpfile("processor_extension.vcd");
        $dumpvars(0, processor_TB);

        clk = 1'b0;
        rst = 1'b1;

        #20;
        rst = 1'b0;

        // Let processor run through instruction memory
        #1000;

        $finish;
    end

endmodule