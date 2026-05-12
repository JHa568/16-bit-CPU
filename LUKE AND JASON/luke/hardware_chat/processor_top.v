`timescale 1ns / 1ps

/*
// Top-level processor module
// Connects together:
// - Register file
// - A register
// - G register
// - ALU
// - Bus multiplexer
// - Controller FSM
*/

module processor_top(

    input clk,
    input rst,
    input run,
/*
clk - cotnrols the timing of the processor, registers and fsm update on clock edges 
rst - resets
run - starts the thing 
*/
    // Instruction inputs
    input [1:0] opcode,
    input [1:0] rx,
    input [1:0] ry,
/*
opcode instructions are (00, LDI) (01, MOV), (10, ADD), (11, SUB)
rx is the destination register
ry is the source register
*/
    // Immediate value for LDI
    input [15:0] immediate,
/*
used for LDI, such that LDI R0, 5 then immediate is 5
*/
    // Instruction finished signal
    output done
);

    // Internal BUS wire
    wire [15:0] bus;

    // Register outputs
    wire [15:0] R0_data;
    wire [15:0] R1_data;
    wire [15:0] R2_data;
/*
these hold the current valus of R0 R1 adn R2
*/

    // A register and G register outputs
    wire [15:0] A_data;
    wire [15:0] G_data;
/*
A_data stoes the first ALU operand
G-data states the ALU results
*/

    // ALU result
     wire [15:0] alu_result;
/*
temp wire that holds the ALU output
*/

    // FSM control signals
    wire [2:0] bus_sel;
    wire R0_en;
    wire R1_en;
    wire R2_en;
    wire A_en;
    wire G_en;
    wire alu_op;
/*
bus_sel - controls what goes on the bus
the R0-en stuff controls which register stores the BUS value. 
A_en and G_en, controls storing into A and G 
alu_op controls the add and the sub
*/

    // Controller FSM
    controller_fsm controller(

        .clk(clk),
        .rst(rst),
        .run(run),

        .opcode(opcode),
        .rx(rx),
        .ry(ry),

        .bus_sel(bus_sel),

        .R0_en(R0_en),
        .R1_en(R1_en),
        .R2_en(R2_en),

        .A_en(A_en),
        .G_en(G_en),

        .alu_op(alu_op),

        .done(done)
    );

    // Register file
    // Contains R0, R1 and R2
    /*
    creates R0 and R1 and R2
    */

    register_file reg_file(

        .clk(clk),
        .rst(rst),

        .bus_in(bus), // means whatever is on bus can enter registers

        .R0_en(R0_en),
        .R1_en(R1_en),
        .R2_en(R2_en),

        .R0_out(R0_data),
        .R1_out(R1_data),
        .R2_out(R2_data)
    );

    // A register
    // Stores first ALU operand

    register_16 A_reg(

        .clk(clk),
        .rst(rst),
        .en(A_en),

        .D(bus), // A register stores bus value
        .Q(A_data)
    );


    // ALU
    // Performs ADD and SUB
    ALU alu(

        .A(A_data),
        .B(bus),

        .alu_ctl(alu_op),

        .Y(alu_result)
    );

    // G register
    // Stores ALU result
    register_16 G_reg(

        .clk(clk),
        .rst(rst),
        .en(G_en),

        .D(alu_result), // stoes ALU result into G
        .Q(G_data)
    );

    // Bus multiplexer
    // Chooses what value goes onto BUS
    bus_mux mux(

        .R0_data(R0_data),
        .R1_data(R1_data),
        .R2_data(R2_data),

        .G_data(G_data),

        .immediate(immediate),

        .bus_sel(bus_sel),

        .bus_out(bus)
    );

endmodule