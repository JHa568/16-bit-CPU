module controller_fsm(
    input clk,
    input status_register, // ALU SR
    input [15:0] instruction,
    output reg [12:0] control_plane
    //  2 |  2 | 2  |  1 | 4  |  1  | 2 |
    // r0 | r1 | r2 | A | ALU | SR | G |
);
    wire opcode = instruction[15:11];

    always @(posedge clk) begin 
        case (opcode)
            `ADD: control_plane = 13'd0;
            `SUB: control_plane = 13'd0;
            `MOV: control_plane = 13'd0;
            `LDI: control_plane = 13'd0;
        endcase
    end
endmodule