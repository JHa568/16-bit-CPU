`ifndef CONTROLLER_TASKS_V
`define CONTROLLER_TASKS_V
`include "constants.v"

// =============================================================
// controller_tasks.v
// -------------------------------------------------------------
// Helper tasks used by controller_fsm.v.
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
//   [10]    sp_push       Decrement stack pointer (after PUSH write)
//   [9]     sp_pop        Increment stack pointer (before POP read)
//   [8]     use_sp_addr   Use SP as data memory address
//   [7:0]   unused        Reserved
// =============================================================

task clear_control;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
    end
endtask

task set_bus;
    input [3:0] source;
    input [31:0] curr;
    output reg [31:0] cp;
    begin
        cp = curr;
        cp[31:28] = source;
    end
endtask

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

task fetch_step;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        cp[13] = 1'b1; // ir_en
    end
endtask

task pc_increment_step;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        cp[15] = 1'b1; // pc_en
    end
endtask

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

task execute_step;
    input [3:0] opcode;
    input [1:0] ry;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
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
        cp[20] = 1'b1; // G_en
        cp[16] = 1'b1; // status_en
    end
endtask

task writeback_step;
    input [1:0] rx;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        set_bus(`BUS_G, cp, cp);
        write_register(rx, cp, cp);
    end
endtask

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
                set_bus(`BUS_IMM, cp, cp);
                write_register(rx, cp, cp);
            end
            `OP_MOV: begin
                read_register(ry, cp, cp);
                set_bus(`BUS_REG, cp, cp);
                write_register(rx, cp, cp);
            end
            `OP_LOAD: begin
                set_bus(`BUS_MEM, cp, cp);
                write_register(rx, cp, cp);
            end
            `OP_STORE: begin
                read_register(rx, cp, cp);
                set_bus(`BUS_REG, cp, cp);
                cp[12] = 1'b1; // mem_write
            end
            `OP_JMP: begin
                cp[14] = 1'b1; // pc_load
            end
            `OP_BEQ: begin
                if (zero_flag)
                    cp[14] = 1'b1;
            end
            default: begin
                cp = 32'd0;
            end
        endcase
    end
endtask

// -------------------------------------------------------------
// PUSH step 1: Rx -> bus -> MEM[SP]
// -------------------------------------------------------------
task push_write_step;
    input [1:0] rx;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        read_register(rx, cp, cp);
        set_bus(`BUS_REG, cp, cp);
        cp[12] = 1'b1;  // mem_write: write bus into MEM[SP]
        cp[8]  = 1'b1;  // use_sp_addr: address = SP
    end
endtask

// -------------------------------------------------------------
// PUSH step 2: SP--
// -------------------------------------------------------------
task push_dec_step;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        cp[10] = 1'b1;  // sp_push: SP = SP - 1
    end
endtask

// -------------------------------------------------------------
// POP step 1: SP++
// -------------------------------------------------------------
task pop_inc_step;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        cp[9] = 1'b1;   // sp_pop: SP = SP + 1
    end
endtask

// -------------------------------------------------------------
// POP step 2: MEM[SP] -> bus -> Rx
// -------------------------------------------------------------
task pop_read_step;
    input [1:0] rx;
    output reg [31:0] cp;
    begin
        cp = 32'd0;
        set_bus(`BUS_MEM, cp, cp);
        cp[8] = 1'b1;   // use_sp_addr: address = SP
        write_register(rx, cp, cp);
    end
endtask

`endif
