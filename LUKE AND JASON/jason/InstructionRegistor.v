module InstructionRegister (
    input clk,
    input reset,
    input load_ir,       // "Enable" signal from the Controller
    input [15:0] din,    // Data coming from Instruction Memory (Dout)
    output reg [15:0] q  // Data going to the Controller (FSM)
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 16'h0000; // Clear the instruction on reset
        end else if (load_ir) begin
            q <= din;      // Capture the instruction when the Controller says "now"
        end
        // If load_ir is 0, the register just keeps holding the old value
    end

endmodule