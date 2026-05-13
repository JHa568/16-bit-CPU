module register_16bit(
    input clk,  // clock
    input rst,  // reset 
    input load, // load new value
    input o_en, // output enabled
    input [15:0] d, // data
    output [15:0] o // output
);
    reg [15:0] data_wire;

    // pipo register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_wire <= 16'h0000; // Clear the register value 
        end else if (load) begin
            data_wire <= d;
        end
    end

    // Tri-state buffer
    assign o = o_en ? data_wire : 16'hzzzz;
endmodule

