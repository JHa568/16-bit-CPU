/*
the instruction register holds the current instruction while the processor executes it.
without the IR, the instruction coming from instruction memory could change while the processor is still working on it.
 we want to store that fetched instruction before decoding/executing it.

 its just a 16 bit register that holds the current instruction 
*/

`timescale 1ns / 1ps

module instruction_register(
    input clk,
    input rst,
    input ir_en, // enable new instruction when high
    input [15:0] instruction_in, // instruction from instruction memory 
    output reg [15:0] instruction_out //store the current instruction.
);
    /*
    Instruction register updates on:
    1. Rising clock edge
    2. Rising reset edge
    */

    always @(posedge clk or posedge rst) begin
        if (rst) // Reset instruction register back to 0
            instruction_out <= 16'd0; // Load fetched instruction into IR
        else if (ir_en) // If ir_en = 0:
            instruction_out <= instruction_in; // keep current instruction stored
    end

endmodule

/*
ir_en = 1 → save fetched instruction
ir_en = 0 → hold current instruction
*/