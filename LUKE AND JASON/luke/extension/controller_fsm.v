`timescale 1ns / 1ps

module controller_fsm(
    input clk,
    input rst,

    input [3:0] opcode,
    input [1:0] rx,
    input [1:0] ry,
    input zero_flag,

    output reg [2:0] bus_sel,

    output reg R0_en,
    output reg R1_en,
    output reg R2_en,

    output reg A_en,
    output reg G_en,

    output reg [2:0] alu_ctl,

    output reg pc_en,
    output reg pc_load,
    output reg ir_en,

    output reg mem_write,
    output reg status_en,

   // --------------------------------------------------------
    output reg sp_push,      // asserted to decrement SP (after PUSH write)
    output reg sp_pop,       // asserted to increment SP (before POP read)
    output reg use_sp_addr,  // use SP as data memory address instead of immediate
    // --------------------------------------------------------
    
   
    output reg done

);

    // Instructions
    parameter LDI   = 4'b0000;
    parameter MOV   = 4'b0001;
    parameter ADD   = 4'b0010;
    parameter SUB   = 4'b0011;
    parameter AND_I = 4'b0100;
    parameter OR_I  = 4'b0101;
    parameter XOR_I = 4'b0110;
    parameter INC   = 4'b0111;
    parameter LOAD  = 4'b1000;
    parameter STORE = 4'b1001;
    parameter JMP   = 4'b1010;
    parameter BEQ   = 4'b1011;
    parameter HALT  = 4'b1111;
    parameter PUSH  = 4'b1100;  // Jason
    parameter POP   = 4'b1101;  // jasooinqwiof

    // Bus sources
    parameter BUS_R0  = 3'b000;
    parameter BUS_R1  = 3'b001;
    parameter BUS_R2  = 3'b010;
    parameter BUS_G   = 3'b011;
    parameter BUS_IMM = 3'b100;
    parameter BUS_MEM = 3'b101;

    // ALU operations
    parameter ALU_ADD = 3'b000;
    parameter ALU_SUB = 3'b001;
    parameter ALU_AND = 3'b010;
    parameter ALU_OR  = 3'b011;
    parameter ALU_XOR = 3'b100;
    parameter ALU_INC = 3'b101;

    // FSM states
    parameter FETCH     = 4'b0000;
    parameter DECODE    = 4'b0001;
    parameter EXEC1     = 4'b0010;
    parameter EXEC2     = 4'b0011;
    parameter EXEC3     = 4'b0100;
    parameter LOAD_EXEC = 4'b0101;
    parameter STORE_EXEC= 4'b0110;
    parameter JMP_EXEC  = 4'b0111;
    parameter BEQ_EXEC  = 4'b1000;
    parameter DONE      = 4'b1001;
    parameter STOP      = 4'b1010;
    parameter PUSH_EXEC1  = 4'b1011;  // asfjioasfjioa
    parameter PUSH_EXEC2  = 4'b1100;  //heheheeee
    parameter POP_EXEC1   = 4'b1101;  // ZNOOOOOOOOOOOOO
    parameter POP_EXEC2   = 4'b1110;  // w

    reg [3:0] state, next_state;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= FETCH;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)

            FETCH: begin
                next_state = DECODE;
            end

            DECODE: begin
                case (opcode)
                    LDI, MOV: begin
                        next_state = DONE;
                    end

                    ADD, SUB, AND_I, OR_I, XOR_I, INC: begin
                        next_state = EXEC1;
                    end

                    LOAD: begin
                        next_state = LOAD_EXEC;
                    end

                    STORE: begin
                        next_state = STORE_EXEC;
                    end

                    JMP: begin
                        next_state = JMP_EXEC;
                    end

                    BEQ: begin
                        next_state = BEQ_EXEC;
                    end
                    //-----------------------------------------
                    PUSH: begin
                        next_state = PUSH_EXEC1; 
                    end
 
                    POP: begin
                        next_state = POP_EXEC1; 
                    end
                    //-----------------------------------------
                    HALT: begin
                        next_state = STOP;
                    end

                    default: begin
                        next_state = DONE;
                    end
                endcase
            end

            EXEC1: begin
                next_state = EXEC2;
            end

            EXEC2: begin
                next_state = EXEC3;
            end

            EXEC3: begin
                next_state = DONE;
            end

            LOAD_EXEC: begin
                next_state = DONE;
            end

            STORE_EXEC: begin
                next_state = DONE;
            end

            JMP_EXEC: begin
                next_state = DONE;
            end

            BEQ_EXEC: begin
                next_state = DONE;
            end
             //--------------------------------------------
            PUSH_EXEC1: begin
                next_state = PUSH_EXEC2; // PUSH: write Rx to mem[SP], then decrement SP
            end
 
            PUSH_EXEC2: begin
                next_state = DONE; 
            end
 
            // POP: increment SP, then read mem[SP] into Rx
            POP_EXEC1: begin
                next_state = POP_EXEC2; 
            end
 
            POP_EXEC2: begin
                next_state = DONE; 
            end
            //--------------------------------------------
            DONE: begin
                next_state = FETCH;
            end

            STOP: begin
                next_state = STOP;
            end

            default: begin
                next_state = FETCH;
            end

        endcase
    end

    // Output control logic
    always @(*) begin

        // Default values
        bus_sel = BUS_R0;

        R0_en = 1'b0;
        R1_en = 1'b0;
        R2_en = 1'b0;

        A_en = 1'b0;
        G_en = 1'b0;

        alu_ctl = ALU_ADD;

        pc_en = 1'b0;
        pc_load = 1'b0;
        ir_en = 1'b0;

        mem_write = 1'b0;
        status_en = 1'b0;
        //---------------------------------------------------------
        sp_push     = 1'b0;
        sp_pop      = 1'b0;
        use_sp_addr = 1'b0;
        //---------------------------------------------------------
        done = 1'b0;

        case (state)

            FETCH: begin
                ir_en = 1'b1;      // load instruction into IR
                pc_en = 1'b1;      // move PC to next instruction
            end

            DECODE: begin
                case (opcode)

                    LDI: begin
                        bus_sel = BUS_IMM;
                        case (rx)
                            2'b00: R0_en = 1'b1;
                            2'b01: R1_en = 1'b1;
                            2'b10: R2_en = 1'b1;
                        endcase
                    end

                    MOV: begin
                        case (ry)
                            2'b00: bus_sel = BUS_R0;
                            2'b01: bus_sel = BUS_R1;
                            2'b10: bus_sel = BUS_R2;
                        endcase

                        case (rx)
                            2'b00: R0_en = 1'b1;
                            2'b01: R1_en = 1'b1;
                            2'b10: R2_en = 1'b1;
                        endcase
                    end

                endcase
            end

            EXEC1: begin
                // Put Rx onto bus and store it into A
                case (rx)
                    2'b00: bus_sel = BUS_R0;
                    2'b01: bus_sel = BUS_R1;
                    2'b10: bus_sel = BUS_R2;
                endcase

                A_en = 1'b1;
            end

            EXEC2: begin
                // Put Ry onto bus and store ALU result into G
                case (ry)
                    2'b00: bus_sel = BUS_R0;
                    2'b01: bus_sel = BUS_R1;
                    2'b10: bus_sel = BUS_R2;
                endcase

                case (opcode)
                    ADD:   alu_ctl = ALU_ADD;
                    SUB:   alu_ctl = ALU_SUB;
                    AND_I: alu_ctl = ALU_AND;
                    OR_I:  alu_ctl = ALU_OR;
                    XOR_I: alu_ctl = ALU_XOR;
                    INC:   alu_ctl = ALU_INC;
                    default: alu_ctl = ALU_ADD;
                endcase

                G_en = 1'b1;
                status_en = 1'b1;
            end

            EXEC3: begin
                // Put G onto bus and write result back into Rx
                bus_sel = BUS_G;

                case (rx)
                    2'b00: R0_en = 1'b1;
                    2'b01: R1_en = 1'b1;
                    2'b10: R2_en = 1'b1;
                endcase
            end

            LOAD_EXEC: begin
                // Memory data goes onto bus, then into Rx
                bus_sel = BUS_MEM;

                case (rx)
                    2'b00: R0_en = 1'b1;
                    2'b01: R1_en = 1'b1;
                    2'b10: R2_en = 1'b1;
                endcase
            end

            STORE_EXEC: begin
                // Rx goes onto bus, data memory writes bus value
                case (rx)
                    2'b00: bus_sel = BUS_R0;
                    2'b01: bus_sel = BUS_R1;
                    2'b10: bus_sel = BUS_R2;
                endcase

                mem_write = 1'b1;
            end

            JMP_EXEC: begin
                pc_load = 1'b1;
            end

            BEQ_EXEC: begin
                if (zero_flag)
                    pc_load = 1'b1;
            end
             //-------------------------------------------
             // PUSH EXEC1: write bus(Rx) into mem[SP]
            PUSH_EXEC1: begin
                case (rx)
                    2'b00: bus_sel = BUS_R0;
                    2'b01: bus_sel = BUS_R1;
                    2'b10: bus_sel = BUS_R2;
                endcase
 
                use_sp_addr = 1'b1;   // address data memory with SP
                mem_write   = 1'b1;   // write to mem[SP] on clock edge
            end
 
            // PUSH EXEC2: decrement SP
            PUSH_EXEC2: begin
                sp_push = 1'b1;       // SP-- on clock edge
            end
 
            // POP EXEC1: increment SP
            POP_EXEC1: begin
                sp_pop = 1'b1;        // SP++ on clock edge
            end
 
            // POP EXEC2: read mem[SP] → Rx
            POP_EXEC2: begin
                bus_sel     = BUS_MEM;   // combinational read of mem[SP]
                use_sp_addr = 1'b1;      // address with updated SP
 
                case (rx)
                    2'b00: R0_en = 1'b1;
                    2'b01: R1_en = 1'b1;
                    2'b10: R2_en = 1'b1;
                endcase
            end
                //-------------------------------------------

            DONE: begin
                done = 1'b1;
            end

            STOP: begin
                done = 1'b1;
            end

        endcase
    end

endmodule