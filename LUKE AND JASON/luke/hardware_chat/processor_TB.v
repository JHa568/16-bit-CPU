/*
LDI R0, 5
LDI R1, 3
ADD R0, R1     // R0 should become 8
SUB R0, R1     // R0 should become 5
MOV R2, R0     // R2 should become 5
were going to test these 5 things
*/

`timescale 1ns / 1ps

module processor_TB;

    reg clk;
    reg rst;
    reg run;

    reg [1:0] opcode;
    reg [1:0] rx;
    reg [1:0] ry;
    reg [15:0] immediate;

    wire done;

    // Opcodes
    parameter LDI = 2'b00;
    parameter MOV = 2'b01;
    parameter ADD = 2'b10;
    parameter SUB = 2'b11;

    processor_top uut(
        .clk(clk),
        .rst(rst),
        .run(run),
        .opcode(opcode),
        .rx(rx),
        .ry(ry),
        .immediate(immediate),
        .done(done)
    );

    // Clock
    always #5 clk = ~clk;

    // Task to run one instruction
    task run_instruction;
        input [1:0] op;
        input [1:0] dest;
        input [1:0] src;
        input [15:0] imm;
        begin
            opcode = op;
            rx = dest;
            ry = src;
            immediate = imm;

            run = 1'b1;
            #10;
            run = 1'b0;

            wait(done == 1'b1);
            #10;
        end
    endtask

    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_TB);

        clk = 0;
        rst = 1;
        run = 0;
        opcode = 0;
        rx = 0;
        ry = 0;
        immediate = 0;

        #20;
        rst = 0;

        // LDI R0, 5
        run_instruction(LDI, 2'b00, 2'b00, 16'd5);

        // LDI R1, 3
        run_instruction(LDI, 2'b01, 2'b00, 16'd3);

        // ADD R0, R1  => R0 = 5 + 3 = 8
        run_instruction(ADD, 2'b00, 2'b01, 16'd0);

        // SUB R0, R1  => R0 = 8 - 3 = 5
        run_instruction(SUB, 2'b00, 2'b01, 16'd0);

        // MOV R2, R0  => R2 = 5
        run_instruction(MOV, 2'b10, 2'b00, 16'd0);

        #50;
        $finish;
    end

endmodule