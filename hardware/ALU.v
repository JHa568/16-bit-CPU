// ALU block
module ALU(
    input [3:0] alu_ctl, 
    input [15:0] a, b,
    output reg [15:0] result,
    output reg [4:0] status
    // Status bits representations [ zero | negative | carry | overflow ]
);
    // Addition Operation
    task add;
        input [15:0] a, b;
        output [15:0] result;
        output reg [3:0] status;
        reg [16:0] tmp;
        reg zero, negative, carry, overflow;
        begin
            
            tmp = a + b;
            result = tmp[15:0];
            negative = tmp[15];
            carry = tmp[16];
            zero = (tmp[15:0] == 16'h0);

            /* Overflow detection
                Checks if the result has already overflowed
                or the result is about the get overflown
            */
            overflow = (a[15] & b[15] & ~result[15]) | 
                                (~a[15] & ~b[15] & result[15]);

            status[0] = overflow;
            status[1] = carry;
            status[2] = negative;
            status[3] = zero;
        end
    endtask

    // Subtraction Operations
    task sub;
        input [15:0] a, b;
        output reg [15:0] result;
        output reg [3:0] status;
        reg [16:0] tmp;
        reg zero, negative, carry, underflow;
        begin
            tmp = a - b; // Same thing as => a + (~b + 1'b1);
            
            result = tmp[15:0];
            negative = tmp[15];
            carry = tmp[16];
            zero = (tmp[15:0] == 16'h0);
            

            /* Underflow detection
                Checks if the result has already overflowed
                or the result is about the get overflown
            */
            underflow = (a[15] & b[15] & ~result[15]) | 
                                (~a[15] & ~b[15] & result[15]);

            status[0] = underflow;
            status[1] = carry;
            status[2] = negative;
            status[3] = zero;
        end
    endtask
    
    always @(*) begin 
        status = 5'd0;
        case (alu_ctl)
            `ADD: add(a, b, result, status[3:0]);
            `SUB: sub(a, b, result, status[3:0]);
            default: 
                begin 
                    result = 16'hDEAD; // Should never hit
                    status[4] = 1'b1; // Returns invalid alu operation
                end
        endcase
    end
endmodule