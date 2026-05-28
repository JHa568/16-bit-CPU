`timescale 1ns / 1ps
`include "constants.v"

// =============================================================
// ALU.v
// -------------------------------------------------------------
// Arithmetic Logic Unit.
//
// The ALU receives two 16-bit inputs:
//   A = first operand stored in the A register
//   B = second operand usually coming from the shared bus
//
// alu_ctl selects which operation is performed.
// The result is combinational, meaning it updates immediately when
// A, B, or alu_ctl changes.
// =============================================================

module ALU(
    input      [15:0] A,        // First ALU operand
    input      [15:0] B,        // Second ALU operand
    input      [2:0]  alu_ctl,  // Operation selector
    output reg [15:0] Y         // ALU result
);

    always @(*) begin
        case (alu_ctl)
            `ALU_ADD: Y = A + B;        // Addition
            `ALU_SUB: Y = A - B;        // Subtraction
            `ALU_AND: Y = A & B;        // Bitwise AND
            `ALU_OR:  Y = A | B;        // Bitwise OR
            `ALU_XOR: Y = A ^ B;        // Bitwise XOR
            `ALU_INC: Y = A + 16'd1;    // Increment A by 1
            default:  Y = 16'd0;        // Safe default
        endcase
    end

endmodule
