`timescale 1ns / 1ps

module fpga_top(
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3
);

    wire rst = ~KEY[0];

    reg [25:0] counter;
    reg slow_clk;

    wire done;
    wire [7:0] pc_debug;
    wire [15:0] instruction_debug;
    wire [15:0] R0_debug;
    wire [15:0] R1_debug;
    wire [15:0] R2_debug;

    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst) begin
            counter <= 26'd0;
            slow_clk <= 1'b0;
        end
        else begin
            if (counter == 26'd24999999) begin
                counter <= 26'd0;
                slow_clk <= ~slow_clk;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

    processor_top cpu(
        .clk(slow_clk),
        .rst(rst),
        .done(done),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .R0_debug(R0_debug),
        .R1_debug(R1_debug),
        .R2_debug(R2_debug)
    );

    assign LEDR[0] = done;
    assign LEDR[8:1] = pc_debug;
    assign LEDR[9] = slow_clk;

    hex_decoder h0(.hex(R0_debug[3:0]), .seg(HEX0));
    hex_decoder h1(.hex(R1_debug[3:0]), .seg(HEX1));
    hex_decoder h2(.hex(R2_debug[3:0]), .seg(HEX2));
    hex_decoder h3(.hex(pc_debug[3:0]), .seg(HEX3));

endmodule


module hex_decoder(
    input [3:0] hex,
    output reg [6:0] seg
);

always @(*) begin
    case (hex)
        4'h0: seg = 7'b1000000;
        4'h1: seg = 7'b1111001;
        4'h2: seg = 7'b0100100;
        4'h3: seg = 7'b0110000;
        4'h4: seg = 7'b0011001;
        4'h5: seg = 7'b0010010;
        4'h6: seg = 7'b0000010;
        4'h7: seg = 7'b1111000;
        4'h8: seg = 7'b0000000;
        4'h9: seg = 7'b0010000;
        4'hA: seg = 7'b0001000;
        4'hB: seg = 7'b0000011;
        4'hC: seg = 7'b1000110;
        4'hD: seg = 7'b0100001;
        4'hE: seg = 7'b0000110;
        4'hF: seg = 7'b0001110;
    endcase
end

endmodule