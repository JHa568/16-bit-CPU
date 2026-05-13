module register_file(
    input clk,
    input rst,
    input wire [5:0] control_plane,
    input [15:0] input_bus,
    output [15:0] output_bus 
);
    
    wire R1_en = control_plane[0];
    wire R1_tri = control_plane[1]; 
    wire R2_en = control_plane[2]; 
    wire R2_tri = control_plane[3]; 
    wire R3_en = control_plane[4]; 
    wire R3_tri = control_plane[5];

    register_16bit R1 (
        .clk(clk), 
        .rst(rst), 
        .load(R1_en), 
        .o_en(R1_en), 
        .d(input_bus), 
        .o(output_bus));

    register_16bit R2 (
        .clk(clk), 
        .rst(rst), 
        .load(R2_en), 
        .o_en(R2_en), 
        .d(input_bus), 
        .o(output_bus));

    register_16bit R3 (
        .clk(clk), 
        .rst(rst), 
        .load(R3_en), 
        .o_en(R3_en), 
        .d(input_bus), 
        .o(output_bus));

endmodule