`timescale 1ns / 1ps

module bus_mux(
    input [15:0] immediate,
    input [15:0] alu,
    input [15:0] registers,  
    input reg [3:0] bus_sel, // 16 possible different options 
    output reg [15:0] bus_out
);

    `include "../constants.v"

    // localparam IMMEDIATE = 4'd1;
    // localparam ALU       = 4'd2;
    // localparam REGISTER  = 4'd3;

    always @(*) begin
        $display("Bus sel: %b | immediate: %h", bus_sel, immediate);
        case (bus_sel)
            `IMMEDIATE: bus_out <= immediate;
            `ALU:       bus_out <= alu;
            `REGISTER:  bus_out <= registers;
            default:   bus_out <= 16'h0000;
        endcase
    end
endmodule