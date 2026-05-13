`timescale 1ns / 1ps

module bus_mux(
    input  [15:0] immediate,
    input         bus_en,
    output reg [15:0] bus_out
);
    always @(*) begin
        if (bus_en) begin
            bus_out = 16'bz;        // register is driving — release the bus
        end else begin
            bus_out = immediate;    // no register active — drive immediate
        end
    end
endmodule