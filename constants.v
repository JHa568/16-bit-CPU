// ALU Operation states
`define ADD 4'b0001 
`define SUB 4'b0010 

`define MOV 4'b0011 // Move to a different register: syntax => MOV Rx Ry
`define LDI 4'b0100 // Store value into register: syntax => LDI Rx D // where D is a constant

`define R0 4'b0001
`define R1 4'b0010
`define R2 4'b0011
`define A 4'b0100
`define G 4'b0101

`define IMMEDIATE 4'd1
`define ALU 4'd2
`define REGISTER 4'd3

`define STORE 1'b0
`define OUTPUT 1'b1