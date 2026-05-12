`timescale 1ns / 1ps

// Register file module
// Contains general purpose registers:
// R0, R1 and R2

module register_file(

    input clk,                 // Clock signal
    input rst,                 // Reset signal

    input [15:0] bus_in,       // Data coming from the processor bus

    // Enable signals for each register
    // If enable = 1, register stores bus_in value
    input R0_en,
    input R1_en,
    input R2_en,

    // Current stored values of registers
    output [15:0] R0_out,
    output [15:0] R1_out,
    output [15:0] R2_out
);

    // Register R0
    register_16 R0_reg(

        .clk(clk),         // Shared processor clock
        .rst(rst),         // Reset R0 back to 0
        .en(R0_en),        // Store data only when enabled

        .D(bus_in),        // Data entering R0 from bus
        .Q(R0_out)         // Current stored value of R0
    );


    // Register R1
    register_16 R1_reg(

        .clk(clk),
        .rst(rst),
        .en(R1_en),

        .D(bus_in),
        .Q(R1_out)
    );

    // Register R2
    register_16 R2_reg(

        .clk(clk),
        .rst(rst),
        .en(R2_en),

        .D(bus_in),
        .Q(R2_out)
    );

endmodule