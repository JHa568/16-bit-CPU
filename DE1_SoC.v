`timescale 1ns / 1ps

// =============================================================
// fpga_top.v
// -------------------------------------------------------------
// DE1-SoC FPGA wrapper for the final CPU.
//
// Board mapping:
//   CLOCK_50 = 50 MHz board clock
//   KEY[0]   = reset button, active low
//   SW[0]    = speed select
//              0: slow visible clock
//              1: faster debug clock
//
// Display mapping:
//   HEX0 = R0 low nibble
//   HEX1 = R1 low nibble
//   HEX2 = R2 low nibble
//   HEX3 = PC low nibble
//   HEX4 = current opcode
//   HEX5 = controller state
//
// LED mapping:
//   LEDR[7:0] = PC value
//   LEDR[8]   = halted flag
//   LEDR[9]   = CPU clock indicator
// =============================================================

module DE1_SoC(
    input        CLOCK_50,
    input  [3:0] KEY,
    input  [9:0] SW,
    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5
);

    // KEY buttons on DE1-SoC are active-low.
    // Pressing KEY0 gives 0, so invert it to make active-high reset.
    wire rst = ~KEY[0];

    // ---------------------------------------------------------
    // Clock divider
    // ---------------------------------------------------------
    reg [25:0] div_counter;
    reg cpu_clk;

    // Choose clock speed using SW[0].
    // Slow mode is easier to observe by eye.
    // Fast mode helps when the program feels too slow.
    wire [25:0] terminal_count = (SW[0]) ? 26'd249999 : 26'd24999999;

    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst) begin
            div_counter <= 26'd0;
            cpu_clk <= 1'b0;
        end
        else begin
            if (div_counter == terminal_count) begin
                div_counter <= 26'd0;
                cpu_clk <= ~cpu_clk;
            end
            else begin
                div_counter <= div_counter + 26'd1;
            end
        end
    end

    // ---------------------------------------------------------
    // CPU debug wires
    // ---------------------------------------------------------
    wire halted_debug;
    wire [3:0]  state_debug;
    wire [7:0]  pc_debug;
    wire [15:0] instruction_debug;
    wire [15:0] R0_debug;
    wire [15:0] R1_debug;
    wire [15:0] R2_debug;
    wire [15:0] mem20_debug;
    wire zero_flag_debug;
    wire [15:0] bus_debug;

    processor_top cpu(
        .clk(cpu_clk),
        .rst(rst),
        .halted_debug(halted_debug),
        .state_debug(state_debug),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .R0_debug(R0_debug),
        .R1_debug(R1_debug),
        .R2_debug(R2_debug),
        .mem20_debug(mem20_debug),
        .zero_flag_debug(zero_flag_debug),
        .bus_debug(bus_debug)
    );

    // LEDs give fast feedback that CPU is alive.
    assign LEDR[7:0] = pc_debug;
    assign LEDR[8]   = halted_debug;
    assign LEDR[9]   = cpu_clk;

    // Seven-segment displays.
    hex_decoder h0(.hex(R0_debug[3:0]),       .seg(HEX0));
    hex_decoder h1(.hex(R1_debug[3:0]),       .seg(HEX1));
    hex_decoder h2(.hex(R2_debug[3:0]),       .seg(HEX2));
    hex_decoder h3(.hex(pc_debug[3:0]),       .seg(HEX3));
    hex_decoder h4(.hex(instruction_debug[15:12]), .seg(HEX4));
    hex_decoder h5(.hex(state_debug),         .seg(HEX5));

endmodule
