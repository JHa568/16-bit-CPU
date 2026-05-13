/*
this is the bit where we do condition branches and compariosn 
such the processor need to remeber the ALU results. 
   the zero flag, neg flag
*/

`timescale 1ns / 1ps

// Status Register
// Stores ALU flags used for conditional branches

module status_register(
    input clk,
    input rst,
    input status_en,
    input [15:0] alu_result,
    output reg zero_flag
);

always @(posedge clk or posedge rst) begin
    // Reset zero flag back to 0
    if (rst) begin
        zero_flag <= 1'b0;
    end
    else if (status_en) begin
        /*
        if ALU result equals 0: zero_flag becomes 1
        else: zero_flag becomes 0
        */
    zero_flag <= (alu_result == 16'd0);
    //if status_en = 0 then keep previous flag value 
    end


end

endmodule