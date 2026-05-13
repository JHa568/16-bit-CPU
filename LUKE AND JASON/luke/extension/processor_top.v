`timescale 1ns / 1ps

module processor_top(
    input clk,
    input rst,

    output done,

    output [7:0] pc_debug,
    output [15:0] instruction_debug,

    output [15:0] R0_debug,
    output [15:0] R1_debug,
    output [15:0] R2_debug
);

    wire [7:0] pc_out;
    wire [15:0] instruction_from_mem;
    wire [15:0] instruction;

    wire [3:0] opcode;
    wire [1:0] rx;
    wire [1:0] ry;
    wire [7:0] immediate;

    wire [15:0] bus;

    wire [15:0] R0_data;
    wire [15:0] R1_data;
    wire [15:0] R2_data;

    wire [15:0] A_data;
    wire [15:0] G_data;
    wire [15:0] alu_result;

    wire [15:0] memory_data;

    wire [2:0] bus_sel;

    wire R0_en;
    wire R1_en;
    wire R2_en;

    wire A_en;
    wire G_en;

    wire [2:0] alu_ctl;

    wire pc_en;
    wire pc_load;
    wire ir_en;

    wire mem_write;
    wire status_en;
    wire zero_flag;

    assign opcode = instruction[15:12];
    assign rx = instruction[11:10];
    assign ry = instruction[9:8];
    assign immediate = instruction[7:0];

    assign pc_debug = pc_out;
    assign instruction_debug = instruction;

    assign R0_debug = R0_data;
    assign R1_debug = R1_data;
    assign R2_debug = R2_data;

    pc pc_inst(
        .clk(clk),
        .rst(rst),
        .pc_en(pc_en),
        .pc_load(pc_load),
        .pc_in(instruction[7:0]),
        .pc_out(pc_out)
    );

    instruction_memory imem(
        .address(pc_out),
        .instruction(instruction_from_mem)
    );

    instruction_register ir(
        .clk(clk),
        .rst(rst),
        .ir_en(ir_en),
        .instruction_in(instruction_from_mem),
        .instruction_out(instruction)
    );

    controller_fsm controller(
        .clk(clk),
        .rst(rst),

        .opcode(opcode),
        .rx(rx),
        .ry(ry),
        .zero_flag(zero_flag),

        .bus_sel(bus_sel),

        .R0_en(R0_en),
        .R1_en(R1_en),
        .R2_en(R2_en),

        .A_en(A_en),
        .G_en(G_en),

        .alu_ctl(alu_ctl),

        .pc_en(pc_en),
        .pc_load(pc_load),
        .ir_en(ir_en),

        .mem_write(mem_write),
        .status_en(status_en),

        .done(done)
    );

    register_file reg_file(
        .clk(clk),
        .rst(rst),
        .bus_in(bus),

        .R0_en(R0_en),
        .R1_en(R1_en),
        .R2_en(R2_en),

        .R0_out(R0_data),
        .R1_out(R1_data),
        .R2_out(R2_data)
    );

    register_16 A_reg(
        .clk(clk),
        .rst(rst),
        .en(A_en),
        .D(bus),
        .Q(A_data)
    );

    ALU alu(
        .A(A_data),
        .B(bus),
        .alu_ctl(alu_ctl),
        .Y(alu_result)
    );

    register_16 G_reg(
        .clk(clk),
        .rst(rst),
        .en(G_en),
        .D(alu_result),
        .Q(G_data)
    );

    data_memory dmem(
        .clk(clk),
        .mem_write(mem_write),
        .address(instruction[7:0]),
        .write_data(bus),
        .read_data(memory_data)
    );

    status_register status(
        .clk(clk),
        .rst(rst),
        .status_en(status_en),
        .alu_result(alu_result),
        .zero_flag(zero_flag)
    );

    bus_mux mux(
        .R0_data(R0_data),
        .R1_data(R1_data),
        .R2_data(R2_data),
        .G_data(G_data),
        .immediate({8'd0, immediate}),
        .memory_data(memory_data),
        .bus_sel(bus_sel),
        .bus_out(bus)
    );

endmodule