`timescale 1ns / 1ps
`include "constants.v"

// =============================================================
// processor_top.v
// -------------------------------------------------------------
// Complete extension CPU.
//
// This module connects:
//   PC -> instruction memory -> instruction register -> controller
//   controller -> datapath control plane
//   register file -> shared bus -> A/ALU/G -> shared bus
//   data memory for LOAD/STORE
//   status register for BEQ
//
// This top module is synthesizable and suitable for both simulation
// and FPGA use through fpga_top.v.
// =============================================================

module processor_top(
    input             clk,
    input             rst,

    output            halted_debug,
    output     [3:0]  state_debug,
    output     [7:0]  pc_debug,
    output     [15:0] instruction_debug,
    output     [15:0] R0_debug,
    output     [15:0] R1_debug,
    output     [15:0] R2_debug,
    output     [15:0] mem20_debug,
    output            zero_flag_debug,
    output     [15:0] bus_debug
);

    // ---------------------------------------------------------
    // Instruction fetch wires
    // ---------------------------------------------------------
    wire [7:0]  pc_out;
    wire [15:0] instruction_from_memory;
    wire [15:0] instruction;

    // Decoded instruction fields
    wire [3:0] opcode = instruction[15:12];
    wire [1:0] rx     = instruction[11:10];
    wire [1:0] ry     = instruction[9:8];
    wire [7:0] imm8   = instruction[7:0]; // bottom 8 bits
    wire [15:0] imm16 = {8'd0, imm8};

    // ---------------------------------------------------------
    // Datapath wires
    // ---------------------------------------------------------
    wire [15:0] bus;
    wire [15:0] reg_out_data;
    wire [15:0] G_data;
    wire [15:0] alu_result;
    wire [15:0] memory_data;

    // ---------------------------------------------------------
    // Controller control signals
    // ---------------------------------------------------------
    wire [31:0] control_plane;
    wire [3:0]  bus_sel;
    wire [1:0]  reg_out_sel;
    wire        reg_out_en;
    wire [1:0]  reg_in_sel;
    wire        reg_in_en;
    wire        A_en;
    wire        G_en;
    wire [2:0]  alu_ctl;
    wire        status_en;
    wire        pc_en;
    wire        pc_load;
    wire        ir_en;
    wire        mem_write;
    wire        halted;
    wire        zero_flag;
    wire [3:0]  controller_state;

    // ---------------------------------------------------------
    // Program Counter
    // pc_in uses the 8-bit immediate/address field for JMP/BEQ.
    // ---------------------------------------------------------
    pc pc_unit(
        .clk(clk),
        .rst(rst),
        .pc_en(pc_en),
        .pc_load(pc_load),
        .pc_in(imm8),
        .pc_out(pc_out)
    );

    // ---------------------------------------------------------
    // Instruction memory
    // PC selects which instruction is fetched.
    // ---------------------------------------------------------
    instruction_memory imem(
        .address(pc_out),
        .instruction(instruction_from_memory)
    );

    // ---------------------------------------------------------
    // Instruction register
    // Stores the current instruction while it executes.
    // ---------------------------------------------------------
    instruction_register ir(
        .clk(clk),
        .rst(rst),
        .ir_en(ir_en),
        .instruction_in(instruction_from_memory),
        .instruction_out(instruction)
    );

    // ---------------------------------------------------------
    // Controller FSM
    // Generates packed control_plane and unpacked datapath signals.
    // ---------------------------------------------------------
    controller_fsm controller(
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .rx(rx),
        .ry(ry),
        .zero_flag(zero_flag),
        .control_plane(control_plane),
        .bus_sel(bus_sel),
        .reg_out_sel(reg_out_sel),
        .reg_out_en(reg_out_en),
        .reg_in_sel(reg_in_sel),
        .reg_in_en(reg_in_en),
        .A_en(A_en),
        .G_en(G_en),
        .alu_ctl(alu_ctl),
        .status_en(status_en),
        .pc_en(pc_en),
        .pc_load(pc_load),
        .ir_en(ir_en),
        .mem_write(mem_write),
        .halted(halted),
        .state_debug(controller_state)
    );

    // ---------------------------------------------------------
    // Register file
    // Holds R0, R1, R2, R3.
    // ---------------------------------------------------------
    register_file regs(
        .clk(clk),
        .rst(rst),
        .bus_in(bus),
        .reg_out_sel(reg_out_sel),
        .reg_in_sel(reg_in_sel),
        .reg_in_en(reg_in_en),
        .reg_out(reg_out_data),
        .R0_debug(R0_debug),
        .R1_debug(R1_debug),
        .R2_debug(R2_debug)
    );

    // ---------------------------------------------------------
    // ALU component
    // Bundles A register + ALU + G register into one unit.
    // ---------------------------------------------------------
    ALU_component alu_unit(
        .clk(clk),
        .rst(rst),
        .bus_in(bus),
        .A_en(A_en),
        .G_en(G_en),
        .alu_ctl(alu_ctl),
        .alu_result(alu_result),
        .G_data(G_data)
    );

    // ---------------------------------------------------------
    // Data memory
    // Address comes from immediate field for simple teaching CPU.
    // STORE writes bus value to memory.
    // LOAD reads memory value into bus through bus_mux.
    // ---------------------------------------------------------
    data_memory dmem(
        .clk(clk),
        .rst(rst),
        .mem_write(mem_write),
        .address(imm8),
        .write_data(bus),
        .read_data(memory_data),
        .mem20_debug(mem20_debug)
    );

    // ---------------------------------------------------------
    // Status register
    // Stores zero flag from ALU result.
    // ---------------------------------------------------------
    status_register status(
        .clk(clk),
        .rst(rst),
        .status_en(status_en),
        .alu_result(alu_result),
        .zero_flag(zero_flag)
    );

    // ---------------------------------------------------------
    // Shared bus mux
    // Chooses which source appears on CPU bus.
    // ---------------------------------------------------------
    bus_mux shared_bus(
        .reg_data(reg_out_en ? reg_out_data : 16'd0),
        .G_data(G_data),
        .immediate(imm16),
        .memory_data(memory_data),
        .bus_sel(bus_sel),
        .bus_out(bus)
    );

    // ---------------------------------------------------------
    // Debug outputs
    // ---------------------------------------------------------
    assign halted_debug      = halted;
    assign state_debug       = controller_state;
    assign pc_debug          = pc_out;
    assign instruction_debug = instruction;
    assign zero_flag_debug   = zero_flag;
    assign bus_debug         = bus;

endmodule
