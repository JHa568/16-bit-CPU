`timescale 1ns / 1ps

// Controller FSM
// Controls execution of:
// LDI, MOV, ADD and SUB instructions

module controller_fsm(
    input clk,
    input rst,
    input run,
/*
clk moves the FSm from one state to the next 
rst send it back to IDLE 
run tell ths FSM to state executing an instruction 
*/

    // Instruction fields
    input [1:0] opcode,
    input [1:0] rx,
    input [1:0] ry,
/*
opcode tells the FSM which instructions: LDI, MOV, ADD or SUB  (e.g. ADD R0, R1)
rx is the destiantion register (e.g. rx = R0)
ry is the source register  (e.g. ry = R1)
*/
    // Control outputs
    output reg [2:0] bus_sel,
    output reg R0_en,
    output reg R1_en,
    output reg R2_en,
/*
27 choese which goes onto the bus (28,29,30)
*/

    output reg A_en,
    output reg G_en,
/*
A_en stores the first ALU input 
G_en stores the ALU input 
*/

    output reg alu_op,
    output reg done
/*
42 choses the ALU operation (0 = Add, 1 = Sub)
goes high whne the instructions has finished. 
*/
    
);

    // Instruction opcodes
    parameter LDI = 2'b00;
    parameter MOV = 2'b01;
    parameter ADD = 2'b10;
    parameter SUB = 2'b11;
/*
Opcodes, the labels for instruction type.
*/
    // Bus select values
    parameter BUS_R0  = 3'b000;
    parameter BUS_R1  = 3'b001;
    parameter BUS_R2  = 3'b010;
    parameter BUS_G   = 3'b011;
    parameter BUS_IMM = 3'b100;
/*
Bus select values - these are labels for what source goes onto the bus
*/
    // FSM states
    parameter IDLE  = 3'b000;
    parameter EXEC1 = 3'b001;
    parameter EXEC2 = 3'b010;
    parameter EXEC3 = 3'b011;
    parameter DONE  = 3'b100;
/*
The FSm moves through these states 
IDLE = waiting
EXEC1 = first execution step 
EXEC2 = seconds execution step 
EXEC3 = third execution step 
DONE = instruction finsihed. 
*/

    reg [2:0] state;
    reg [2:0] next_state;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end
/*
on reset go back to IDLE,
otherwise on each of the clock edge, move to the calulated next_State. 
*/

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (run)
                    next_state = EXEC1;
                else
                    next_state = IDLE;
            end
/*
Wait until run  = 1
*/

            EXEC1: begin
                // ADD and SUB need multiple states
                if (opcode == ADD || opcode == SUB)
                    next_state = EXEC2;
                // LDI and MOV finish immediately
                else
                    next_state = DONE;
            end
/*
LDI and MOV in one step 
ADd and SUB need more steps. 
*/

            EXEC2: begin
                next_state = EXEC3;
            end
/*
after ALU caluclation move to write back 
*/

            EXEC3: begin
                next_state = DONE;
            end
/*
after writing result back, instruction is done. 
*/

            DONE: begin
                next_state = IDLE;
            end
/*
retuns to waiting state.
*/

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output control logic
    always @(*) begin

        // Default values
        bus_sel = 3'b000;

        R0_en = 0;
        R1_en = 0;
        R2_en = 0;
        A_en = 0;
        G_en = 0;
        alu_op = 0;
        done = 0;
/*
prevents the old signal from staying on accidentally. 
*/

        case (state)
            // EXEC1
            EXEC1: begin
                case (opcode)
                    // LDI

                    LDI: begin
                        bus_sel = BUS_IMM;
                        case (rx)
                            2'b00: R0_en = 1;
                            2'b01: R1_en = 1;
                            2'b10: R2_en = 1;
                        endcase
                    end
/*
175 put immediate value on the bus 
then rx decided which register enables  (e.g. LDI R0, 5, -> immediate goes on bus, R0_en =1 )
*/

                    // MOV
                    MOV: begin
                        case (ry)
                            2'b00: bus_sel = BUS_R0;
                            2'b01: bus_sel = BUS_R1;
                            2'b10: bus_sel = BUS_R2;
                        endcase

                        case (rx)
                            2'b00: R0_en = 1;
                            2'b01: R1_en = 1;
                            2'b10: R2_en = 1;
                        endcase
                    end
/*
ry decided bus_sel 
rx decided register nable 
so then MOV R0, R1 -> R1 goes onthe bus, R0_en = 1
*/
                    // ADD / SUB
                    // Move Rx into A register
                    ADD,
                    SUB: begin
                        case (rx)
                            2'b00: bus_sel = BUS_R0;
                            2'b01: bus_sel = BUS_R1;
                            2'b10: bus_sel = BUS_R2;
                        endcase
                        A_en = 1;
                    end
                endcase
            end
/*
rx goes onto the bus A_en = 1 
ADD R0, R1 step 1: 
R0 -> bus -> A
*/
            // EXEC2
            // ALU operation
            EXEC2: begin
                case (ry)
                    2'b00: bus_sel = BUS_R0;
                    2'b01: bus_sel = BUS_R1;
                    2'b10: bus_sel = BUS_R2;
                endcase

                // SUB uses alu_op = 1
                if (opcode == SUB)
                    alu_op = 1'b1;
                G_en = 1;

            end

            // EXEC3
            // Write G back into Rx

            EXEC3: begin
                bus_sel = BUS_G;
                case (rx)
                    2'b00: R0_en = 1;
                    2'b01: R1_en = 1;
                    2'b10: R2_en = 1;
                endcase
            end
            // DONE

            DONE: begin
                done = 1;
            end

        endcase

    end

endmodule