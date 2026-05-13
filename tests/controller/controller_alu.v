module controller_alu();
    reg clk;
    
    wire [15:0] instruction;

    wire [1:0] r0;
    wire [1:0] r1;
    wire [1:0] r2;
    wire [1:0] A;
    wire [3:0] ALU;  
    wire [4:0] SR;
    wire [1:0] G; 

    wire [15:0] comm_bus;

    // ONLY used in test bench
    reg [3:0] counter;

    initial begin
        // ----- For Mac Users ------
        // Remove if needed
        $dumpfile("ctrl_alu.vcd");
        $dumpvars(0, controller_alu);
        // --------------------------

        clk = 0;
        instruction = 16'h0000; // ADD R1 R2
        comm_bus = 16'h0000;
    
        counter = 4'd0;

        #20000
        $finish
    end

    wire [5:0] reg_wires;
    wire [3:0] alu_reg_wires;

    assign reg_wires[1:0] = r0;
    assign reg_wire[3:2]  = r1;
    assign reg_wire[4:5]  = r2;
    
    assign alu_reg_wires[3:2] = A;
    assign alu_reg_wires[1:0] = G;

    register_file reg_file(.clk(clk), .rst(1'b0), .control_plane(reg_wires), .bus(comm_bus), .output_bus(comm_bus));
    
    wire [15:0] Rx;
    wire [15:0] G_wires;
    wire [4:0] SR; // Status register.

    // NOTE: keep register wires consistent convention
    register_16bit A_register(
        .clk(clk), 
        .rst(1'b0), 
        .load(alu_reg_wires[3]), 
        .o_en(alu_reg_wires[2]), 
        .d(comm_bus), 
        .o(Rx)
    );

    register_16bit G_register(
        .clk(clk), 
        .rst(1'b0), 
        .load(alu_reg_wires[1]), 
        .o_en(alu_reg_wires[0]),
        .d(G_wires), 
        .o(comm_bus)
    );

    ALU alu_component(.alu_ctl(ALU), .a(Rx), .b(comm_bus), .result(G_wires), .status(SR));

    controller_fsm control(
        .clk(clk), 
        .status_register(SR), 
        .instruction(instruction), 
        .r0(r0),
        .r1(r1),
        .r2(r2),
        .A(A),
        .ALU(ALU),
        .SR(SR),
        .G(G)
    );

endmodule