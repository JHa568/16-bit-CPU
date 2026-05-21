`timescale 1ns / 1ps
`include "constants.v"

// =============================================================
// register_file.v
// -------------------------------------------------------------
// Four general-purpose 16-bit registers: R0, R1, R2, R3.
//
// The controller chooses:
//   reg_out_sel = which register appears on reg_out
//   reg_in_sel  = which register stores bus_in
//   reg_in_en   = whether a register write occurs
//
// This is still a shared-bus style design. The register file does
// not directly drive the final CPU bus; instead it produces reg_out,
// and bus_mux decides whether reg_out appears on the shared bus.
// =============================================================

module register_file(
    input             clk,
    input             rst,

    input      [15:0] bus_in,       // Data to write into selected register
    input      [1:0]  reg_out_sel,  // Selects register to read
    input      [1:0]  reg_in_sel,   // Selects register to write
    input             reg_in_en,    // Write enable

    output reg [15:0] reg_out,      // Selected register output

    output reg [15:0] R0_debug,     // Debug output for R0
    output reg [15:0] R1_debug,     // Debug output for R1
    output reg [15:0] R2_debug,     // Debug output for R2
    output reg [15:0] R3_debug      // Debug output for R3
);

    // ---------------------------------------------------------
    // Sequential write logic
    // Registers update only on the rising clock edge.
    // ---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            R0_debug <= 16'd0;
            R1_debug <= 16'd0;
            R2_debug <= 16'd0;
            R3_debug <= 16'd0;
        end
        else if (reg_in_en) begin
            case (reg_in_sel)
                `REG_R0: R0_debug <= bus_in;
                `REG_R1: R1_debug <= bus_in;
                `REG_R2: R2_debug <= bus_in;
                `REG_R3: R3_debug <= bus_in;
                default: begin end
            endcase
        end
    end

    // ---------------------------------------------------------
    // Combinational read logic
    // The selected register appears immediately on reg_out.
    // ---------------------------------------------------------
    always @(*) begin
        case (reg_out_sel)
            `REG_R0: reg_out = R0_debug;
            `REG_R1: reg_out = R1_debug;
            `REG_R2: reg_out = R2_debug;
            `REG_R3: reg_out = R3_debug;
            default: reg_out = 16'd0;
        endcase
    end

endmodule
