`timescale 1ns / 1ps
`include "constants.v"

// =============================================================
// ALU.v
// -------------------------------------------------------------
// Arithmetic Logic Unit with SIMD support.
//
// The ALU receives two 16-bit inputs:
//   A = first operand stored in the A register
//   B = second operand usually coming from the shared bus
//
// alu_ctl selects which operation is performed.
// mode selects the lane width:
//   2'b00 = scalar (normal 16-bit)
//   2'b01 = SIMD 2x (2 × 8-bit lanes)
//   2'b10 = SIMD 4x (4 × 4-bit lanes)
//
// Lane isolation for ADD/SUB is achieved by performing each
// lane's operation on its own slice — no carry can cross
// lane boundaries. AND/OR/XOR are bitwise and inherently
// lane-agnostic, so they require no SIMD changes.
// =============================================================

module ALU(
    input      [15:0] A,        // First ALU operand
    input      [15:0] B,        // Second ALU operand
    input      [1:0]  mode,     // 00=scalar | 01=SIMD 2x8 | 10=SIMD 4x4
    input      [2:0]  alu_ctl,  // Operation selector
    output reg [15:0] Y         // ALU result
);

    // ----------------------------------------------------------
    // SIMD 2×8-bit lane wires
    // Each lane is an independent 8-bit operation.
    // Carry cannot cross the 8-bit boundary.
    // ----------------------------------------------------------
    wire [7:0] simd2_add_hi = A[15:8] + B[15:8];
    wire [7:0] simd2_add_lo = A[7:0]  + B[7:0];

    wire [7:0] simd2_sub_hi = A[15:8] - B[15:8];
    wire [7:0] simd2_sub_lo = A[7:0]  - B[7:0];

    // ----------------------------------------------------------
    // SIMD 4×4-bit lane wires
    // Each lane is an independent 4-bit operation.
    // Carry cannot cross any 4-bit boundary.
    // ----------------------------------------------------------
    wire [3:0] simd4_add_a = A[15:12] + B[15:12];
    wire [3:0] simd4_add_b = A[11:8]  + B[11:8];
    wire [3:0] simd4_add_c = A[7:4]   + B[7:4];
    wire [3:0] simd4_add_d = A[3:0]   + B[3:0];

    wire [3:0] simd4_sub_a = A[15:12] - B[15:12];
    wire [3:0] simd4_sub_b = A[11:8]  - B[11:8];
    wire [3:0] simd4_sub_c = A[7:4]   - B[7:4];
    wire [3:0] simd4_sub_d = A[3:0]   - B[3:0];

    // ----------------------------------------------------------
    // ALU operation select
    // ----------------------------------------------------------
    always @(*) begin
        case (alu_ctl)

            `ALU_ADD: begin
                case (mode)
                    2'b00:   Y = A + B;                                     // Scalar 16-bit
                    2'b01:   Y = { simd2_add_hi, simd2_add_lo };            // 2×8-bit
                    2'b10:   Y = { simd4_add_a, simd4_add_b,
                                   simd4_add_c, simd4_add_d };              // 4×4-bit
                    default: Y = A + B;
                endcase
            end

            `ALU_SUB: begin
                case (mode)
                    2'b00:   Y = A - B;                                     // Scalar 16-bit
                    2'b01:   Y = { simd2_sub_hi, simd2_sub_lo };            // 2×8-bit
                    2'b10:   Y = { simd4_sub_a, simd4_sub_b,
                                   simd4_sub_c, simd4_sub_d };              // 4×4-bit
                    default: Y = A - B;
                endcase
            end

            // Bitwise ops work per-bit — naturally lane-agnostic
            `ALU_AND: Y = A & B;
            `ALU_OR:  Y = A | B;
            `ALU_XOR: Y = A ^ B;

            // INC only meaningful in scalar mode
            `ALU_INC: Y = A + 16'd1;

            default:  Y = 16'd0;

        endcase
    end

endmodule