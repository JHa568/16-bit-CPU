`timescale 1ns / 1ps

// =============================================================
// data_memory.v
// -------------------------------------------------------------
// Simple 256 x 16-bit data memory.
//
// LOAD uses read_data = memory[address].
// STORE writes memory[address] <= write_data on clock edge.
//
// For this teaching CPU, memory addresses come directly from the
// 8-bit immediate/address field in the instruction.
// =============================================================

module data_memory(
    input             clk,
    input             rst,
    input             mem_write,
    input      [7:0]  address,
    input      [15:0] write_data,
    output     [15:0] read_data,
    output     [15:0] mem20_debug
);

    reg [15:0] memory [0:255];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1) begin
                memory[i] <= 16'd0;
            end
        end
        else if (mem_write) begin
            memory[address] <= write_data;
        end
    end

    // Combinational read: changing address immediately changes read_data.
    assign read_data = memory[address];

    // Debug output so testbench/FPGA can show that STORE worked.
    assign mem20_debug = memory[8'd20];

endmodule
