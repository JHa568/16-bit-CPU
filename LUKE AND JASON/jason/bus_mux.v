`timescale 1ns / 1ps
`include "constants.v"

// =============================================================
// bus_mux.v
// -------------------------------------------------------------
// Shared bus multiplexer.
//
// In a textbook diagram, multiple units may connect to one bus
// using tri-state buffers. Inside an FPGA, internal tri-state buses
// are usually implemented more safely as multiplexers.
//
// This module decides which value is currently placed on the
// processor's shared bus.
// =============================================================

module bus_mux(
    input      [15:0] reg_data,     // Selected register file output
    input      [15:0] G_data,       // G register output
    input      [15:0] immediate,    // Zero-extended immediate value
    input      [15:0] memory_data,  // Data memory output
    input      [3:0]  bus_sel,      // Bus source selector
    output reg [15:0] bus_out       // Final shared bus value
);

    always @(*) begin
        case (bus_sel)
            `BUS_ZERO: bus_out = 16'd0;
            `BUS_REG:  bus_out = reg_data;
            `BUS_G:    bus_out = G_data;
            `BUS_IMM:  bus_out = immediate;
            `BUS_MEM:  bus_out = memory_data;
            default:   bus_out = 16'd0;
        endcase
    end

endmodule
