// LOAD tasks 
task load_step;
    input [3:0] opcode;
    input [11:0] params;
    output reg [20:0] control_plane
    begin
        `include "../../constants.v";
        `include "./register_tasks.v";
        
        reg [1:0] Rx;

        always @(*) begin
            case(opcode)
                `ADD, `SUB: begin
                    Rx = params[11:10];
                    get_register(Rx, `OUTPUT, control_plane, control_plane);
                    get_register(`A, `STORE, control_plane, control_plane);
                end
                default: begin end
            endcase
        end
    end
endtask

// EXECUTE tasks
task execute_step;
    input [3:0] opcode;
    input [11:0] params;
    output reg [20:0] control_plane
    begin
        `include "../../constants.v";
        `include "./register_tasks.v";
        
        reg [1:0] Ry;

        always @(*) begin
            case(opcode)
                `ADD, `SUB: begin
                    Ry = params[9:8];
                    control_plane[3:0] = opcode;
                    get_register(Ry, `OUTPUT, control_plane, control_plane);
                    get_register(`G, `STORE, control_plane, control_plane);
                end
                default: begin end
            endcase
        end
    end
endtask

// WRITEBACK tasks
task writeback_step;
    input [3:0] opcode;
    input [11:0] params;
    input [15:0] curr_comm_bus;
    output reg [20:0] control_plane;
    output reg [15:0] comm_bus;

    begin
        `include "../../constants.v";
        `include "./register_tasks.v";

        reg [1:0] Rx = params[11:10]; // Used by SUB, ADD, MOV, LDI
        reg [1:0] Ry = params[9:8]; // Used by SUB, ADD, MOV
        reg [3:0] D = params[9:6]; // Used by LDI
        always @(*) begin
            case(opcode)
                `ADD, `SUB: begin
                    get_register(`G, `OUTPUT, control_plane, control_plane);
                    get_register(Rx, `STORE, control_plane, control_plane);
                end
                `MOV: begin
                    get_register(Rx, `OUTPUT, control_plane, control_plane);
                    get_register(Ry, `STORE, control_plane, control_plane);
                    $display("MOV has been done!");
                end
                `LDI: begin
                    get_register(Rx, `STORE, control_plane, control_plane);
                    control_plane[20] = 1'b1;
                    comm_bus[3:0] = D;
                    $display("LDI has been done!");
                end
                default: begin end
            endcase
        end
    end
endtask