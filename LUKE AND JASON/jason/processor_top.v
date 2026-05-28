`timescale 1ns / 1ps
`include "constants.v"

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
    output     [15:0] bus_debug,
    output     [7:0]  sp_debug       // stack pointer for debug/FPGA
);

    // ---------------------------------------------------------
    // Instruction fetch wires
    // ---------------------------------------------------------
    wire [7:0]  pc_out;
    wire [15:0] instruction_from_memory;
    wire [15:0] instruction;

    wire [3:0] opcode = instruction[15:12];
    wire [1:0] rx     = instruction[11:10];
    wire [1:0] ry     = instruction[9:8];
    wire [7:0] imm8   = instruction[7:0];
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

    // Stack pointer control signals
    wire        sp_push;
    wire        sp_pop;
    wire        use_sp_addr;

    // ---------------------------------------------------------
    // Stack Pointer
    // Full-descending: starts at 0xFF (top of data memory)
    // PUSH: write to mem[SP], then SP--
    // POP:  SP++, then read from mem[SP]
    // ---------------------------------------------------------
    reg [7:0] SP;

    always @(posedge clk or posedge rst) begin
        if (rst)
            SP <= 8'hFF;
        else if (sp_push)
            SP <= SP - 1'b1;
        else if (sp_pop)
            SP <= SP + 1'b1;
    end

    // Address mux: SP for stack operations, immediate for LOAD/STORE
    wire [7:0] dmem_addr = use_sp_addr ? SP : imm8;

    // ---------------------------------------------------------
    // Program Counter
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
    // ---------------------------------------------------------
    instruction_memory imem(
        .address(pc_out),
        .instruction(instruction_from_memory)
    );

    // ---------------------------------------------------------
    // Instruction register
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
        .sp_push(sp_push),
        .sp_pop(sp_pop),
        .use_sp_addr(use_sp_addr),
        .state_debug(controller_state)
    );

    // ---------------------------------------------------------
    // Register file
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
    // ---------------------------------------------------------
    data_memory dmem(
        .clk(clk),
        .rst(rst),
        .mem_write(mem_write),
        .address(dmem_addr),
        .write_data(bus),
        .read_data(memory_data),
        .mem20_debug(mem20_debug)
    );

    // ---------------------------------------------------------
    // Status register
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
    assign sp_debug          = SP;

endmodule
