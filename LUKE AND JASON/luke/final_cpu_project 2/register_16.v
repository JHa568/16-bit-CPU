`timescale 1ns / 1ps

// =============================================================
// register_16.v
// -------------------------------------------------------------
// Generic 16-bit register with reset and enable.
// Used for the special A and G registers.
//
// If rst = 1: register clears to 0.
// Else if en = 1 on a rising clock edge: Q loads D.
// Else: Q keeps its old value.
// =============================================================

module register_16(
    input             clk,  // Clock signal
    input             rst,  // Active-high reset
    input             en,   // Enable load signal
    input      [15:0] D,    // Data input
    output reg [15:0] Q     // Stored register output
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Q <= 16'd0;
        end
        else if (en) begin
            Q <= D;
        end
    end

endmodule
