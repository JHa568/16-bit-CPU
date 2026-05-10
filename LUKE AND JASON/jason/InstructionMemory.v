module InstructionMemory (
    input [15:0] address,    // From the Program Counter (PC)
    output [15:0] q          // To the Instruction Register (IR)
);

    // Create an array for the memory (e.g., 256 words of 16-bits each)
    reg [15:0] rom [255:0];

    // Load the machine code into the memory at startup
    initial begin
        // This looks for a file called "program.mem" in your project folder
        $readmemh("program.mem", rom); 
    end

    // The read logic is combinational (asynchronous)
    // As soon as the PC address changes, the instruction changes
    assign q = rom[address];

endmodule