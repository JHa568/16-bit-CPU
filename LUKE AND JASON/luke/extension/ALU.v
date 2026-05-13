module ALU (
    input [15:0] A,
    input [15:0] B,
    input [2:0] alu_ctl,
    output reg [15:0] Y
);

    // ALU control codes
    parameter ALU_ADD = 3'b000;
    parameter ALU_SUB = 3'b001;
    parameter ALU_AND = 3'b010;
    parameter ALU_OR  = 3'b011;
    parameter ALU_XOR = 3'b100;
    parameter ALU_INC = 3'b101;

    always @(*) begin
        case (alu_ctl)

            ALU_ADD: begin
                Y = A + B;
            end

            ALU_SUB: begin
                Y = A - B;
            end

            ALU_AND: begin
                Y = A & B;
            end

            ALU_OR: begin
                Y = A | B;
            end

            ALU_XOR: begin
                Y = A ^ B;
            end

            ALU_INC: begin
                Y = A + 16'd1;
            end

            default: begin
                Y = 16'd0;
            end

        endcase
    end

endmodule