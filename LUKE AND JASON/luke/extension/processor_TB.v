// pc is is the program counter and is used to determine the next set of instructions. 
/*
Hold a 16-bit address
On reset -> go to 0
Normally -> increment by 1 each fetch
On a jump/branch → load a new address instead
*/

`timescale 1ns / 1ps

module pc(
    input clk, // the clock, the PC upadtes on rising edges
    input rst, // send the PC back to the address of 0 
    input pc_en, // enable, when high, the PC increments by 1, move onto the next instruction
    input pc_load, // load, when high, the PC would have to jump to pc_in instead of incrementing. 
    input [7:0] pc_in, // pc_in is the addres that it would jump to, so it would be used for the jmp and branch. 
    output reg [7:0] pc_out // this is the current address that would be sent to instructin memory. 

);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        pc_out <= 8'd0; // on a reset, go back to the first instruction which is address 0 
    end
    else if (pc_load) begin
        pc_out <= pc_in; // jump: load a new address, pc_load takes priority over pc_en.
    end
    else if (pc_en) begin
        pc_out <= pc_out + 1'b1; // normal fetch move to the next instruction
    end
end // is neither pc_load and pc_en, the PC jsut hold the current value. 

endmodule



 
