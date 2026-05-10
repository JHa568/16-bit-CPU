`timescale 1ns / 1ps

// Selects which value goes onto the processor bus
// bus_sel = 000 → bus = R0
// bus_sel = 001 → bus = R1
// bus_sel = 010 → bus = R2
// bus_sel = 011 → bus = G
// bus_sel = 100 → bus = immediate


module bus_mux(

    input [15:0] R0_data,
    input [15:0] R1_data,
    input [15:0] R2_data,
    input [15:0] G_data,
    input [15:0] immediate,
    input [2:0] bus_sel,
    output reg [15:0] bus_out

);

    // Bus select codes

    parameter BUS_R0  = 3'b000;
    parameter BUS_R1  = 3'b001;
    parameter BUS_R2  = 3'b010;
    parameter BUS_G   = 3'b011;
    parameter BUS_IMM = 3'b100;

    always @(*) begin

        case (bus_sel)
            BUS_R0: begin
                bus_out = R0_data;
            end
            BUS_R1: begin
                bus_out = R1_data;
            end
            BUS_R2: begin
                bus_out = R2_data;
            end
            BUS_G: begin
                bus_out = G_data;
            end
            BUS_IMM: begin
                bus_out = immediate;
            end
            default: begin
                bus_out = 16'd0;
            end
        endcase
    end

endmodule