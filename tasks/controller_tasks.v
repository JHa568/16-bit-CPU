`include "constants.v"
`include "register_tasks.v"

// LOAD tasks 
task load_step; 
    input [3:0] opcode;
    input [11:0] params;
    output reg [23:0] control_plane;
    reg [3:0] Rx;
    begin // 
        control_plane = 24'd0;
        Rx = params[11:8];
        case(opcode)
            `ADD: begin 
                $display("LOADING ADD!");
                get_register(Rx, `OUTPUT, control_plane, control_plane);
                get_register(`A,  `STORE,  control_plane, control_plane);
                control_plane[23:20] = `REGISTER;
                $display("LOADING ADD control _plane = %b!", control_plane);
            end
            `SUB: begin
                get_register(Rx, `OUTPUT, control_plane, control_plane);
                get_register(`A,  `STORE,  control_plane, control_plane);
                control_plane[23:20] = `REGISTER;
            end
            default: begin end
        endcase
    end
endtask

// EXECUTE tasks
task execute_step;
    input [3:0] opcode;
    input [11:0] params;
    output reg [23:0] control_plane;
    reg [3:0] Ry;
    begin 
        control_plane = 24'd0;
        Ry = params[7:4];
        case(opcode)
            `ADD: begin
                control_plane[3:0] = opcode;
                get_register(Ry, `OUTPUT, control_plane, control_plane);
                get_register(`G,  `STORE,  control_plane, control_plane);
                control_plane[23:20] = `REGISTER;
            end
            `SUB: begin
                control_plane[3:0] = opcode;
                get_register(Ry, `OUTPUT, control_plane, control_plane);
                get_register(`G,  `STORE,  control_plane, control_plane);
                control_plane[23:20] = `REGISTER;
            end
            // Why no 
            default: begin end
        endcase
    end
endtask

// WRITEBACK tasks
task writeback_step;
    input [3:0] opcode;
    input [11:0] params;
    output reg [23:0] control_plane;
    output reg [15:0] imm_bus;// Only used by LDI command
    reg [3:0] Rx;
    reg [3:0] Ry;
    reg [15:0] D;
    begin
        control_plane = 24'd0;
        Rx = params[11:8];
        Ry = params[7:4];
        D  = {8'b0, params[7:0]};              // 4-bit immediate follows Rx in LDI encoding
        $display("opcode = %b!", opcode);
        case(opcode)
            `ADD: begin
                get_register(`G,  `OUTPUT, control_plane, control_plane);
                get_register(Rx,  `STORE,  control_plane, control_plane);
                control_plane[23:20] = `ALU;
            end
            `SUB: begin
                get_register(`G,  `OUTPUT, control_plane, control_plane);
                get_register(Rx,  `STORE,  control_plane, control_plane);
                control_plane[23:20] = `ALU;
            end
            `MOV: begin
                get_register(Rx, `OUTPUT, control_plane, control_plane);
                get_register(Ry, `STORE,  control_plane, control_plane);
                control_plane[23:20] = `REGISTER;
            end
            `LDI: begin // 
                $display("LDI Begin!!--------------");
                get_register(Rx, `STORE, control_plane, control_plane);
                control_plane[23:20] = `IMMEDIATE;
                imm_bus = D; 
                $display("imm_bus: %h", D);
                $display("LDI has been done!----------------");
            end
            default: begin end
        endcase
    end
endtask