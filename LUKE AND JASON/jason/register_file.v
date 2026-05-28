`timescale 1ns / 1ps
`include "constants.v"

module register_file(
    input             clk,
    input             rst,

    input      [15:0] bus_in,
    input      [1:0]  reg_out_sel,
    input      [1:0]  reg_in_sel,
    input             reg_in_en,

    output reg [15:0] reg_out,

    output reg [15:0] R0_debug,
    output reg [15:0] R1_debug,
    output reg [15:0] R2_debug
);

    reg [15:0] r0, r1, r2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r0 <= 16'd0;
            r1 <= 16'd0;
            r2 <= 16'd0;
        end
        else if (reg_in_en) begin
            case (reg_in_sel)
                `REG_R0: r0 <= bus_in;
                `REG_R1: r1 <= bus_in;
                `REG_R2: r2 <= bus_in;
                default: begin end
            endcase
        end
    end

    always @(*) begin
        case (reg_out_sel)
            `REG_R0: reg_out = r0;
            `REG_R1: reg_out = r1;
            `REG_R2: reg_out = r2;
            default: reg_out = 16'd0;
        endcase
    end

    always @(*) begin
        R0_debug = r0;
        R1_debug = r1;
        R2_debug = r2;
    end

endmodule
