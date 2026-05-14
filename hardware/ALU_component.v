module ALU_component(
    input clk, 
    input rst,
    input [3:0] alu_ctl,
    input [3:0] control_plane,
    input [15:0] input_bus,
    output [15:0] output_bus,
    output [15:0] status_bus
);  
    wire [15:0] accumulator_wire, g_reg_wire, sr_reg_wire;
    wire [4:0] status_reg_wire;
    wire A_en = control_plane[3];
    wire A_tri = |alu_ctl;
    wire G_en = control_plane[1];
    wire G_tri = control_plane[0];

    register_16bit A(
        .clk(clk), 
        .rst(rst), 
        .load(A_en), 
        .o_en(A_tri), 
        .d(input_bus), 
        .o(accumulator_wire)
    ); // Accumulator

    register_16bit G(
        .clk(clk), 
        .rst(rst), 
        .load(G_en), 
        .o_en(G_tri), 
        .d(g_reg_wire), 
        .o(output_bus)
    ); // G register to store the computed module

    // register_16bit SR (
    //     .clk(clk), 
    //     .rst(rst), 
    //     .load(A_tri), 
    //     .o_en(G_tri), 
    //     .d(sr_reg_wire), 
    //     .o(status_bus)
    // ); // SR register, status register

    ALU alu_compute(
        .alu_ctl(alu_ctl), 
        .a(accumulator_wire), 
        .b(input_bus),
        .result(g_reg_wire),
        .status() // Not handling this at the moment
    ); 
endmodule