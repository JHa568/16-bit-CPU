`timescale 1ns / 1ps

// 16-bit register module
// Used for R0, R1, R2, A and G registers

module register_16(

    input clk,            // Clock signal
    input rst,            // Reset signal
    input en,             // Enable signal: allows register to store new data

    input [15:0] D,       // 16-bit input data

    output reg [15:0] Q   // 16-bit stored output value
);

// Register updates only on:
// 1. Rising clock edge
// 2. Rising reset edge

always @(posedge clk or posedge rst) begin
    // Reset register value back to 0
    if (rst) begin
        Q <= 16'd0;
    end
    // Store new value only if enable is ON
    else if (en) begin
        Q <= D;
    end
    // If enable = 0:
    // keep previous stored value automatically

end

endmodule