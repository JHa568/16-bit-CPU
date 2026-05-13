module controller_fsm(
    input clk,
    input status_register,
    input [15:0] instruction,
    input [15:0] curr_comm_bus,
    output reg [1:0] r0,
    output reg [1:0] r1,
    output reg [1:0] r2,
    output reg [1:0] A,
    output reg [3:0] ALU,
    output reg [4:0] SR,
    output reg [1:0] G,
    output reg [3:0] bus_sel,
    output reg [15:0] out_comm_bus
);
    `include "tasks/controller_tasks.v"

    localparam C_FETCH   = 3'd0;
    localparam C_DECODE  = 3'd1;
    localparam C_LOAD    = 3'd2;
    localparam C_EXECUTE = 3'd3;
    localparam C_WRITE   = 3'd4;

    reg [3:0] op_code;
    reg [11:0] params;
    reg [2:0] controller_state;
    reg [23:0] control_plane = 24'd0;

    initial begin
        controller_state = C_FETCH;
        op_code = 4'd0;
        params  = 12'd0;
    end
    
    always @(*) begin
        control_plane = 24'd0; // default everything off
        case(controller_state)
            C_LOAD: begin 
                load_step(op_code, params, control_plane);
            end
            C_EXECUTE: begin
                execute_step(op_code, params, control_plane);
            end
            C_WRITE: begin
                $display("Before Register: %b", control_plane[23:20]);
                writeback_step(
                    op_code,
                    params,
                    control_plane,
                    out_comm_bus
                );
                $display("After Register: %b", control_plane[23:20]);
            end
            default: control_plane = 24'd0;
        endcase

        bus_sel = control_plane[23:20];
        r0     = control_plane[19:18];
        r1     = control_plane[17:16];
        r2     = control_plane[15:14];
        A      = control_plane[13:12];
        G      = control_plane[11:10];
        SR     = control_plane[9:4];
        ALU    = control_plane[3:0];
    end

    always @(posedge clk) begin
        // control_plane = 24'd0;    // blocking — task writes take effect
        case(controller_state)
            C_FETCH: begin
                controller_state <= C_DECODE;
            end
            C_DECODE: begin
                op_code <= instruction[15:12];
                params  <= instruction[11:0];
                controller_state <= C_LOAD;
            end
            C_LOAD: begin
                controller_state <= C_EXECUTE;
            end
            C_EXECUTE: begin
                controller_state <= C_WRITE;
            end
            C_WRITE: begin
                controller_state <= C_FETCH;
            end
            default: begin
                controller_state <= C_FETCH;
            end
        endcase
    end

endmodule