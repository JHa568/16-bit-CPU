`timescale 1ns / 1ps

// =============================================================
// instruction_register.v
// -------------------------------------------------------------
// Instruction Register (IR).
//
// Instruction memory output can change whenever PC changes.
// The IR stores the fetched instruction so that the controller can
// safely decode and execute the same instruction across multiple
// clock cycles.
// =============================================================

module instruction_register(
    input             clk,
    input             rst,
    input             ir_en,           // Load enable
    input      [15:0] instruction_in,  // From instruction memory
    output reg [15:0] instruction_out  // Stable current instruction
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instruction_out <= 16'd0;
        end
        else if (ir_en) begin
            instruction_out <= instruction_in;
        end
    end

endmodule
