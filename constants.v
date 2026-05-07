// ALU Operation states
`define ADD 4'b0001 
`define SUB 4'b0010 

`define MOV 4'b0011 // Move to a different register: syntax => MOV Rx Ry
`define LDI 4'b0100 // Store value into register: syntax => LDI Rx D // where D is a constant

