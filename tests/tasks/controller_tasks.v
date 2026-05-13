// LOAD tasks 
task load_step;
    input [3:0] opcode;
    input [11:0] params;
    output reg [19:0] control_plane
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
                `MOV: begin
                end
                `LDI: begin
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
    output reg [19:0] control_plane
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
                `MOV: begin
                end
                `LDI: begin
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
    output reg [19:0] control_plane;

    begin
        `include "../../constants.v";
        `include "./register_tasks.v";

        always @(*) begin
            case(opcode)
                `ADD, `SUB: begin
                    get_register(`G, `OUTPUT, control_plane, control_plane);
                    get_register(Rx, `STORE, control_plane, control_plane);
                end
                `MOV: begin
                    $display("MOV not implemented!");
                end
                `LDI: begin
                    $display("LDI not implemented!");
                end
                default: begin end
            endcase
        end
    end
endtask