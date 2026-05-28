`timescale 1ns / 1ps

module ALU_component(
    input             clk,
    input             rst,
    input      [15:0] bus_in,
    input             A_en,
    input             G_en,
    input      [2:0]  alu_ctl,
    output     [15:0] alu_result,
    output     [15:0] G_data
);

    wire [15:0] A_data;

    register_16 A_reg(
        .clk(clk),
        .rst(rst),
        .en(A_en),
        .D(bus_in),
        .Q(A_data)
    );

    ALU alu(
        .A(A_data),
        .B(bus_in),
        .alu_ctl(alu_ctl),
        .Y(alu_result)
    );

    register_16 G_reg(
        .clk(clk),
        .rst(rst),
        .en(G_en),
        .D(alu_result),
        .Q(G_data)
    );

endmodule
