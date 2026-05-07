module register_16bit(
    input clk, // clk
    input clear,
    input [15:0] d, // data
    output reg [15:0] o // output
);
    // pipo register
    always @(posedge clk or posedge clear) begin
        if (clear) begin
            o <= 16'd0; // Clear the register value 
        end else begin
            o <= d;
        end
    end
endmodule