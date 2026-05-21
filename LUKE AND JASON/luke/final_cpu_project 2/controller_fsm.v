`timescale 1ns / 1ps
`include "constants.v"
`include "controller_tasks.v"

// =============================================================
// controller_fsm.v
// -------------------------------------------------------------
// Multi-cycle CPU controller using a packed control-plane style.
//
// This module is the brain of the processor. It does not store data
// or perform arithmetic directly. Instead, it generates control
// signals that tell the datapath what to do each clock cycle.
//
// Main stages:
//   FETCH     : PC selects instruction memory and IR loads instruction.
//   PC_INC    : PC increments AFTER the IR has latched safely.
//   DECODE    : Controller looks at the opcode and decides what path.
//   LOAD_A    : For ALU instructions, Rx is loaded into A.
//   EXEC_ALU  : Ry goes to bus, ALU result is stored in G.
//   WRITEBACK : G goes to bus, result is written back into Rx.
//   HALTED    : Processor stops after HALT instruction.
// =============================================================

module controller_fsm(
    input             clk,
    input             rst,

    input      [3:0]  opcode,     // instruction[15:12]
    input      [1:0]  rx,         // instruction[11:10]
    input      [1:0]  ry,         // instruction[9:8]
    input             zero_flag,  // from status register

    output reg [31:0] control_plane,

    // Unpacked control signals used by the datapath
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
    output reg [3:0]  state_debug
);

    // Controller states
    localparam S_FETCH     = 4'd0;  // latch instruction at current PC into IR
    localparam S_PC_INC    = 4'd1;  // increment PC after IR has latched
    localparam S_DECODE    = 4'd2;  // decode/handle current IR instruction
    localparam S_LOAD_A    = 4'd3;  // load Rx into A for ALU instructions
    localparam S_EXEC_ALU  = 4'd4;  // execute ALU operation and store result in G
    localparam S_WRITEBACK = 4'd5;  // write G result back into Rx
    localparam S_HALTED    = 4'd6;  // stop processor

    reg [3:0] state;
    reg [3:0] next_state;

    // ---------------------------------------------------------
    // State register
    // ---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_FETCH;
        end
        else begin
            state <= next_state;
        end
    end

    // ---------------------------------------------------------
    // Next-state logic
    // ---------------------------------------------------------
    always @(*) begin
        case (state)
            S_FETCH: begin
                // First latch instruction_memory[PC] into the IR.
                // Do NOT increment PC in this same state, otherwise the IR/PC timing is ambiguous.
                next_state = S_PC_INC;
            end

            S_PC_INC: begin
                // Now that the IR safely holds the current instruction, move PC to the next address.
                next_state = S_DECODE;
            end

            S_DECODE: begin
                case (opcode)
                    `OP_ADD, `OP_SUB, `OP_AND, `OP_OR, `OP_XOR, `OP_INC: begin
                        next_state = S_LOAD_A;
                    end
                    `OP_HALT: begin
                        next_state = S_HALTED;
                    end
                    default: begin
                        // LDI, MOV, LOAD, STORE, JMP, BEQ complete in DECODE.
                        next_state = S_FETCH;
                    end
                endcase
            end

            S_LOAD_A: begin
                next_state = S_EXEC_ALU;
            end

            S_EXEC_ALU: begin
                next_state = S_WRITEBACK;
            end

            S_WRITEBACK: begin
                next_state = S_FETCH;
            end

            S_HALTED: begin
                next_state = S_HALTED;
            end

            default: begin
                next_state = S_FETCH;
            end
        endcase
    end

    // ---------------------------------------------------------
    // Output/control logic
    // The controller generates one packed control word, then unpacks
    // it into named signals for the datapath.
    // ---------------------------------------------------------
    always @(*) begin
        control_plane = 32'd0;

        case (state)
            S_FETCH: begin
                // Latch the instruction at the current PC into the instruction register.
                fetch_step(control_plane);
            end

            S_PC_INC: begin
                // Increment PC one cycle later, after IR has already captured the instruction.
                pc_increment_step(control_plane);
            end

            S_DECODE: begin
                simple_instruction_step(opcode, rx, ry, zero_flag, control_plane);
            end

            S_LOAD_A: begin
                load_step(rx, control_plane);
            end

            S_EXEC_ALU: begin
                execute_step(opcode, ry, control_plane);
            end

            S_WRITEBACK: begin
                writeback_step(rx, control_plane);
            end

            S_HALTED: begin
                control_plane = 32'd0;
                control_plane[11] = 1'b1;
            end

            default: begin
                control_plane = 32'd0;
            end
        endcase

        // Unpack the control plane.
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
        state_debug = state;
    end

endmodule
