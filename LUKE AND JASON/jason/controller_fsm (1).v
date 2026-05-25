`timescale 1ns / 1ps
`include "constants.v"

module controller_fsm(
    input             clk,
    input             rst,

    input      [3:0]  opcode,
    input      [1:0]  rx,
    input      [1:0]  ry,
    input             zero_flag,

    output reg [31:0] control_plane,

    output reg [3:0]  bus_sel,
    output reg [1:0]  reg_out_sel,
    output reg        reg_out_en,
    output reg [1:0]  reg_in_sel,
    output reg        reg_in_en,
    output reg        A_en,
    output reg        G_en,
    output reg [2:0]  alu_ctl,
    output reg        status_en,
    output reg        pc_en,
    output reg        pc_load,
    output reg        ir_en,
    output reg        mem_write,
    output reg        halted,

    // Stack pointer control signals
    output reg        sp_push,
    output reg        sp_pop,
    output reg        use_sp_addr,

    output reg [3:0]  state_debug
);

    `include "controller_tasks.v"

    // Controller states
    localparam S_FETCH      = 4'd0;
    localparam S_PC_INC     = 4'd1;
    localparam S_DECODE     = 4'd2;
    localparam S_LOAD_A     = 4'd3;
    localparam S_EXEC_ALU   = 4'd4;
    localparam S_WRITEBACK  = 4'd5;
    localparam S_HALTED     = 4'd6;
    localparam S_PUSH_WRITE = 4'd7;   // write Rx to MEM[SP]
    localparam S_PUSH_DEC   = 4'd8;   // decrement SP
    localparam S_POP_INC    = 4'd9;   // increment SP
    localparam S_POP_READ   = 4'd10;  // read MEM[SP] into Rx

    reg [3:0] state;
    reg [3:0] next_state;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_FETCH;
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        case (state)
            S_FETCH: begin
                next_state = S_PC_INC;
            end

            S_PC_INC: begin
                next_state = S_DECODE;
            end

            S_DECODE: begin
                case (opcode)
                    `OP_ADD, `OP_SUB, `OP_AND, `OP_OR, `OP_XOR, `OP_INC: begin
                        next_state = S_LOAD_A;
                    end
                    `OP_PUSH: next_state = S_PUSH_WRITE;
                    `OP_POP:  next_state = S_POP_INC;
                    `OP_HALT: next_state = S_HALTED;
                    default:  next_state = S_FETCH; // LDI, MOV, LOAD, STORE, JMP, BEQ
                endcase
            end

            S_LOAD_A:     next_state = S_EXEC_ALU;
            S_EXEC_ALU:   next_state = S_WRITEBACK;
            S_WRITEBACK:  next_state = S_FETCH;
            S_HALTED:     next_state = S_HALTED;

            S_PUSH_WRITE: next_state = S_PUSH_DEC;
            S_PUSH_DEC:   next_state = S_FETCH;
            S_POP_INC:    next_state = S_POP_READ;
            S_POP_READ:   next_state = S_FETCH;

            default: next_state = S_FETCH;
        endcase
    end

    // Output/control logic
    always @(*) begin
        control_plane = 32'd0;

        case (state)
            S_FETCH:      fetch_step(control_plane);
            S_PC_INC:     pc_increment_step(control_plane);
            S_DECODE:     simple_instruction_step(opcode, rx, ry, zero_flag, control_plane);
            S_LOAD_A:     load_step(rx, control_plane);
            S_EXEC_ALU:   execute_step(opcode, ry, control_plane);
            S_WRITEBACK:  writeback_step(rx, control_plane);

            S_PUSH_WRITE: push_write_step(rx, control_plane);
            S_PUSH_DEC:   push_dec_step(control_plane);
            S_POP_INC:    pop_inc_step(control_plane);
            S_POP_READ:   pop_read_step(rx, control_plane);

            S_HALTED: begin
                control_plane = 32'd0;
                control_plane[11] = 1'b1; // halted
            end

            default: control_plane = 32'd0;
        endcase

        // Unpack control plane into named signals
        bus_sel     = control_plane[31:28];
        reg_out_sel = control_plane[27:26];
        reg_out_en  = control_plane[25];
        reg_in_sel  = control_plane[24:23];
        reg_in_en   = control_plane[22];
        A_en        = control_plane[21];
        G_en        = control_plane[20];
        alu_ctl     = control_plane[19:17];
        status_en   = control_plane[16];
        pc_en       = control_plane[15];
        pc_load     = control_plane[14];
        ir_en       = control_plane[13];
        mem_write   = control_plane[12];
        halted      = control_plane[11];
        sp_push     = control_plane[10];
        sp_pop      = control_plane[9];
        use_sp_addr = control_plane[8];
        state_debug = state;
    end

endmodule
