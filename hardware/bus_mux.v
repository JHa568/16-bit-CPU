`timescale 1ns / 1ps

// Selects which value goes onto the processor bus

module bus_mux(
    input [15:0] immediate,
    input reg bus_en,
    output reg [15:0] bus_out
);
    always @(*) begin
        if (bus_en) begin
            bus_out = immediate;
        end else begin
            bus_out = 16'd0;
        end
    end
endmodule