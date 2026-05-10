module ALU (
    input [15:0] A,
    input [15:0] B,
    input alu_ctl,
    output reg [15:0] Y
);

always @(*) begin
    case (alu_ctl)
        1'b0: Y = A + B;
        1'b1: Y = A - B;
    endcase
end

endmodule
