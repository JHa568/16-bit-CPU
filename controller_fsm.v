module controller_fsm(
    input clk,
    input status_register, // ALU SR
    input [15:0] instruction,
    input [15:0] curr_comm_bus,
    output [1:0] r0,
    output [1:0] r1,
    output [1:0] r2,
    output [1:0] A,
    output [3:0] ALU,  
    output [4:0] SR,
    output [1:0] G,
    output bus_en, // Bus MUX 
    output [15:0] out_comm_bus,

    // JASON AND LUKE IMPLEMENT:
    // Program counter
    // Instruction 

    // output [3:0] PC, // Program counter
    // output reg instruction_end // next queue trigger for next instruction.
    );  

    `include "./tasks/operation_tasks.v"
    `include "./tasks/controller_tasks.v";

    localparam C_FETCH = 3'd0;   // Fetches instruction 
    localparam C_DECODE = 3'd1;  // Decodes the instruction (opcode + params)
    localparam C_LOAD = 3'd2;    // Loads to the accumulator or some other temporary storage to be computed by EXECUTE
    localparam C_EXECUTE = 3'd3; // Executes basically computes values (anything that transforms one or more values to a single value)
    localparam C_WRITE = 3'd4;   // Writes to a specific register

    wire [3:0] opcode; 
    wire [11:0] params; 
    reg [2:0] controller_state;
    reg [20:0] control_plane;

    initial begin
        controller_state = C_FETCH;
        opcode = 4'd0; 
        params = 12'd0;
    end

    always @(posedge clk) begin
        control_plane = 21'd0;
        case (controller_state);
            `C_FETCH: begin
                instruction_end = 1'b1;
                controller_state <= `C_DECODE;
            end
            `C_DECODE begin
                opcode <= instruction[15:12];
                params <= instruction[11:0];
                controller_state <= `C_LOAD;
            end
            `C_LOAD: begin
                load_step(op_code, params, control_plane);
                controller_state <= `C_EXECUTE;
            end
            `C_EXECUTE: begin
                execute_step(op_code, params, control_plane);
                controller_state <= `C_WRITE;
            end
            `C_WRITE: begin
                writeback_step(op_code, params, curr_comm_bus, control_plane, out_comm_bus);
                controller_state <= `C_FETCH;
            end
            default: 
        endcase
    end
    
    // Assign the control plane the wires
    // Mux enable flag for bus
    assign bus_en = control_plane[20];

    // Registers at the top
    assign r0 = control_plane[19:18]
    assign r1 = control_plane[17:16]
    assign r2 = control_plane[15:14]
    assign A = control_plane[13:12]
    assign G = control_plane[11:10]

    // Other registers
    assign SR = control_plane[9:4]
    assign ALU = control_plane[3:0]
endmodule