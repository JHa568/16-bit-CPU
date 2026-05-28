`timescale 1ns / 1ps

// =============================================================
// status_register.v
// -------------------------------------------------------------
// Stores ALU status flags.
// Currently stores only zero_flag.
//
// zero_flag = 1 when ALU result is 0.
// This is used by BEQ to decide whether to branch.
// =============================================================

module status_register(
    input             clk,
    input             rst,
    input             status_en,
    input      [15:0] alu_result,
    output reg        zero_flag
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            zero_flag <= 1'b0;
        end
        else if (status_en) begin
            zero_flag <= (alu_result == 16'd0);
        end
    end

endmodule
