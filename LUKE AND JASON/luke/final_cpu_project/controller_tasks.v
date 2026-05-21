`ifndef CONTROLLER_TASKS_V
`define CONTROLLER_TASKS_V
`include "constants.v"

// =============================================================
// controller_tasks.v
// -------------------------------------------------------------
// Helper tasks used by controller_fsm.v.
//
// The tutor-approved style your friend used is based around a
// packed control word. This file keeps that idea.
//
// control_plane bit layout:
//   [31:28] bus_sel       Which source goes onto shared bus
//   [27:26] reg_out_sel   Which register is read
//   [25]    reg_out_en    Read enable/debug signal
//   [24:23] reg_in_sel    Which register is written
//   [22]    reg_in_en     Register write enable
//   [21]    A_en          Load A register from bus
//   [20]    G_en          Load G register from ALU result
//   [19:17] alu_ctl       ALU operation
//   [16]    status_en     Update zero flag
//   [15]    pc_en         PC increments
//   [14]    pc_load       PC loads jump/branch target
//   [13]    ir_en         Instruction register loads
//   [12]    mem_write     Data memory write enable
//   [11]    halted        Processor halted indicator
//   [10:0]  unused        Reserved for future extension
// =============================================================

// -------------------------------------------------------------
// clear_control
// Sets all control signals to zero/off.
// -------------------------------------------------------------
task clear_control;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
    end
endtask

// -------------------------------------------------------------
// set_bus
// Chooses which source appears on the shared bus.
// -------------------------------------------------------------
task set_bus;
    input [3:0] source;
    input [31:0] curr;
    output reg [31:0] cp;
    begin
        cp = curr;
        cp[31:28] = source;
    end
endtask

// -------------------------------------------------------------
// read_register
// Selects a register as the register-file output.
// The actual final bus source still needs BUS_REG selected.
// -------------------------------------------------------------
task read_register;
    input [1:0] reg_id;
    input [31:0] curr;
    output reg [31:0] cp;
    begin
        cp = curr;
        cp[27:26] = reg_id;
        cp[25] = 1'b1;
    end
endtask

// -------------------------------------------------------------
// write_register
// Selects a register to store the shared bus value.
// -------------------------------------------------------------
task write_register;
    input [1:0] reg_id;
    input [31:0] curr;
    output reg [31:0] cp;
    begin
        cp = curr;
        cp[24:23] = reg_id;
        cp[22] = 1'b1;
    end
endtask

// -------------------------------------------------------------
// fetch_step
// Loads current instruction into IR and increments PC.
// PC and IR update on the same rising clock edge.
// -------------------------------------------------------------
task fetch_step;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        cp[13] = 1'b1; // ir_en
        cp[15] = 1'b1; // pc_en
    end
endtask

// -------------------------------------------------------------
// load_step
// First ALU step: move Rx into A.
// Example ADD R0,R1:
//   R0 -> bus -> A
// -------------------------------------------------------------
task load_step;
    input [1:0] rx;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        read_register(rx, cp, cp);
        set_bus(`BUS_REG, cp, cp);
        cp[21] = 1'b1; // A_en
    end
endtask

// -------------------------------------------------------------
// execute_step
// Second ALU step: place Ry on bus, choose ALU operation,
// store ALU result into G, and update status flags.
// -------------------------------------------------------------
task execute_step;
    input [3:0] opcode;
    input [1:0] ry;
    output reg [31:0] cp;
    begin
        cp = 32'd0;

        // Most ALU operations use Ry as the second operand.
        // INC ignores the bus inside the ALU, but selecting ZERO keeps
        // the datapath quiet and easier to debug.
        if (opcode == `OP_INC) begin
            set_bus(`BUS_ZERO, cp, cp);
        end
        else begin
            read_register(ry, cp, cp);
            set_bus(`BUS_REG, cp, cp);
        end

        case (opcode)
            `OP_ADD: cp[19:17] = `ALU_ADD;
            `OP_SUB: cp[19:17] = `ALU_SUB;
            `OP_AND: cp[19:17] = `ALU_AND;
            `OP_OR:  cp[19:17] = `ALU_OR;
            `OP_XOR: cp[19:17] = `ALU_XOR;
            `OP_INC: cp[19:17] = `ALU_INC;
            default: cp[19:17] = `ALU_ADD;
        endcase

        cp[20] = 1'b1; // G_en: store ALU result into G
        cp[16] = 1'b1; // status_en: update zero flag from ALU result
    end
endtask

// -------------------------------------------------------------
// writeback_step
// Final ALU step: move G result back into Rx.
// Example ADD R0,R1:
//   G -> bus -> R0
// -------------------------------------------------------------
task writeback_step;
    input [1:0] rx;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        set_bus(`BUS_G, cp, cp);
        write_register(rx, cp, cp);
    end
endtask

// -------------------------------------------------------------
// simple_instruction_step
// Handles instructions that complete in one controller state:
// LDI, MOV, LOAD, STORE, JMP, BEQ, HALT.
// -------------------------------------------------------------
task simple_instruction_step;
    input [3:0] opcode;
    input [1:0] rx;
    input [1:0] ry;
    input zero_flag;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        case (opcode)
            `OP_LDI: begin
                // Immediate -> bus -> Rx
                set_bus(`BUS_IMM, cp, cp);
                write_register(rx, cp, cp);
            end

            `OP_MOV: begin
                // Ry -> bus -> Rx
                read_register(ry, cp, cp);
                set_bus(`BUS_REG, cp, cp);
                write_register(rx, cp, cp);
            end

            `OP_LOAD: begin
                // MEM[address] -> bus -> Rx
                set_bus(`BUS_MEM, cp, cp);
                write_register(rx, cp, cp);
            end

            `OP_STORE: begin
                // Rx -> bus -> MEM[address]
                read_register(rx, cp, cp);
                set_bus(`BUS_REG, cp, cp);
                cp[12] = 1'b1; // mem_write
            end

            `OP_JMP: begin
                cp[14] = 1'b1; // pc_load
            end

            `OP_BEQ: begin
                if (zero_flag) begin
                    cp[14] = 1'b1; // pc_load only when zero flag is set
                end
            end

            `OP_HALT: begin
                cp[11] = 1'b1; // halted
            end

            default: begin
                cp = 32'd0;
            end
        endcase
    end
endtask

`endif
