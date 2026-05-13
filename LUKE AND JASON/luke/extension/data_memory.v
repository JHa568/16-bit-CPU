
/*
the data memory is usef for load and store insturctions 
store: the fsm assets the mem_write =1, such the data written on rising clock edge 
laodL the fsm assets mem_write = 0, data_out is available combinationally. 

the data memory lets the processor store data permanently outside the registers.
its used for load and store, such that we dont use the registers. 
*/


`timescale 1ns / 1ps

// Data Memory
// Used for LOAD and STORE instructions

module data_memory(
    input clk,
    input mem_write,
    input [7:0] address,
    input [15:0] write_data,
    output [15:0] read_data
);

    // 256 memory locations, each 16 bits wide
    reg [15:0] memory [255:0];

    // Read is combinational
    assign read_data = memory[address];
/*
This is always active — whatever address is on the input, the data at that location is immediately on read_data. 
No clock needed. The FSM just puts it on the bus when it needs it
*/

    // Write happens on clock edge update the memory address 
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address] <= write_data;
        end
    end

/*
writes only happen on the rising clock edge, and only when mem_write = 1. 
this is the STORE instruction — the FSM asserts mem_write, puts the register value on write_data, 
and puts the target address on address, and on the next clock edge the value gets saved.
*/

endmodule