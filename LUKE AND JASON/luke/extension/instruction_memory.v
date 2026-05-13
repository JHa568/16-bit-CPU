/* now given such that the PC is giving instruction, we need to fetch the instructions from somewhere
the general idea is such the PC - instruction memory -> then execute the instruction 
the processor now reads them automatically from memory.
the instruction memory will:
- store the program
- take the PC address as input
- output the instruction at that address
note that PC would not increment when doing like jump or any conditional branches. 
*/

`timescale 1ns / 1ps
module instruction_memory(

    input [7:0] address,          // Address from PC
    output [15:0] instruction     // Instruction at that address
);
    // Memory array
    // 256 memory locations
    reg [15:0] memory [255:0];
    // Example program stored in instruction memory
    initial begin
        // Address 0: LDI R0, 5
        memory[0] = 16'b0000_00_00_00000101;
        // Address 1: LDI R1, 3
        memory[1] = 16'b0000_01_00_00000011;
        // Address 2: ADD R0, R1
        memory[2] = 16'b0010_00_01_00000000;
        // Address 3: SUB R0, R1
        memory[3] = 16'b0011_00_01_00000000;
        // Address 4: MOV R2, R0
        memory[4] = 16'b0001_10_00_00000000;

/*
R0:0 → 5 → 8 → 5
R1: 0 → 3
R2:0 → 5
*/


/*
initial begin
    // R0 = 5
    memory[0]  = 16'b0000_00_00_00000101; // LDI R0, 5

    // R1 = 3
    memory[1]  = 16'b0000_01_00_00000011; // LDI R1, 3

    // R0 = R0 + R1 = 8
    memory[2]  = 16'b0010_00_01_00000000; // ADD R0, R1

    // R0 = R0 - R1 = 5
    memory[3]  = 16'b0011_00_01_00000000; // SUB R0, R1

    // R2 = R0 = 5
    memory[4]  = 16'b0001_10_00_00000000; // MOV R2, R0

    // R2 = R2 AND R1 = 5 AND 3 = 1
    memory[5]  = 16'b0100_10_01_00000000; // AND R2, R1

    // R2 = R2 OR R1 = 1 OR 3 = 3
    memory[6]  = 16'b0101_10_01_00000000; // OR R2, R1

    // R2 = R2 XOR R0 = 3 XOR 5 = 6
    memory[7]  = 16'b0110_10_00_00000000; // XOR R2, R0

    // R2 = R2 + 1 = 7
    memory[8]  = 16'b0111_10_00_00000000; // INC R2

    // Store R2 into memory address 20
    memory[9]  = 16'b1001_10_00_00010100; // STORE R2, [20]

    // Load memory[20] into R1
    memory[10] = 16'b1000_01_00_00010100; // LOAD R1, [20]

    // R0 = R0 - R0 = 0, sets zero_flag = 1
    memory[11] = 16'b0011_00_00_00000000; // SUB R0, R0

    // If zero_flag == 1, jump to address 14
    memory[12] = 16'b1011_00_00_00001110; // BEQ 14

    // This should be skipped
    memory[13] = 16'b0000_10_00_11111111; // LDI R2, 255

    // R2 = 9
    memory[14] = 16'b0000_10_00_00001001; // LDI R2, 9

    // Jump to address 17
    memory[15] = 16'b1010_00_00_00010001; // JMP 17

    // This should be skipped
    memory[16] = 16'b0000_01_00_11111111; // LDI R1, 255

    // Stop
    memory[17] = 16'b1111_00_00_00000000; // HALT
end
R0 = 0
R1 = 7
R2 = 9
memory[20] = 7
zero_flag = 1
*/

/*
16'b0010_00_01_00000000
break is up into 0010 00 01 00000000
[15:12] - opcode
[11:10] - rx
[9:8] - ry
[7:0] - immediate
*/

    end
    // Output instruction at current address
    assign instruction = memory[address];

endmodule

