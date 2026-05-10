//alu.v more stuff
// Bitwise AND
    task bit_and;
        input [15:0] a, b;
        output [15:0] result;
        output reg [3:0] status;
        begin
            result = a & b;
            status[3] = (result == 16'h0); // Zero flag
            status[2] = result[15];        // Negative flag (MSB is 1)
            status[1] = 1'b0;              // No carry for logic
            status[0] = 1'b0;              // No overflow for logic
        end
    endtask

    // Bitwise OR
    task bit_or;
        input [15:0] a, b;
        output [15:0] result;
        output reg [3:0] status;
        begin
            result = a | b;
            status[3] = (result == 16'h0);
            status[2] = result[15];
            status[1] = 1'b0;
            status[0] = 1'b0;
        end
    endtask

    // Bitwise XOR
    task bit_xor;
        input [15:0] a, b;
        output [15:0] result;
        output reg [3:0] status;
        begin
            result = a ^ b;
            status[3] = (result == 16'h0);
            status[2] = result[15];
            status[1] = 1'b0;
            status[0] = 1'b0;
        end
    endtask