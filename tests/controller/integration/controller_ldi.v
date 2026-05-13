`timescale 1ns / 1ps

module controller_ldi;

    reg clk;
    reg status_register;
    reg [15:0] instruction;

    wire [1:0] r0, r1, r2, A, G;
    wire [3:0] ALU;
    wire [4:0] SR;
    
    wire [3:0] bus_sel;
    wire [15:0] imm_bus;
    wire [15:0] alu_bus;
    wire [15:0] reg_bus;

    wire [15:0] bus;
    wire [15:0] rf_out_bus;

    integer pass = 0;
    integer fail = 0;
    
    assign alu_bus = 16'b0;
    assign reg_bus = 16'b0;

    // reg [3:0] bus_sel_reg;
    // reg [15:0] bus_reg;

    controller_fsm dut (
        .clk(clk),
        .status_register(status_register),
        .instruction(instruction),
        .curr_comm_bus(bus),
        .r0(r0), .r1(r1), .r2(r2),
        .A(A),
        .ALU(ALU),
        .SR(SR),
        .G(G),
        .bus_sel(bus_sel),
        .out_comm_bus(imm_bus)
    );

    bus_mux mux (
        .immediate (imm_bus), // Output direct from controller
        .alu       (alu_bus), // Output from ALU NOT BEING USED
        .registers (reg_bus), // Output for register NOT BEING USED
        .bus_sel   (bus_sel), 
        .bus_out   (bus)
    );

    register_file rf (
        .clk(clk),
        .rst(1'b0),
        .control_plane({r0, r1, r2}),
        .input_bus(bus),
        .output_bus(rf_out_bus)
    );

    always #5 clk = ~clk;

    task tick;
    begin
        #10;
    end
    endtask

    task check;
        input [63:0] cond;    // integer-like, pick a width
        input [127:0] msg;    // packed byte array for string
        begin
            if (cond) begin
                $display("  [PASS] %s", msg);
                pass = pass + 1;
            end else begin
                $display("  [FAIL] %s", msg);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("ldi.vcd");
        $dumpvars(0, controller_ldi);
        $display("\n╔══════════════════════════════════════════════╗");
        $display("║               LDI Integration Suite         ║");
        $display("╚══════════════════════════════════════════════╝");

        clk = 0;

        // LDI R0, 0x0D
        instruction = {4'h4, 4'h1, 8'h0D};

        tick(); // FETCH
        tick(); // DECODE
        tick(); // LOAD
        tick(); // EXECUTE
        tick(); // WRITEBACK
        // Force r0 to "active/read" state to trigger rf output
        force r0 = 2'b01;  // whatever value makes register_file output R0
        #1;                // settle
        
        $display("rf_out_bus = %h", rf_out_bus);
        check(rf_out_bus == 16'h000D, "LDI loads immediate 0x000D into R0");
        
        release r0;        // give control back to FSM

        //tick(); tick(); tick(); tick(); // Finish the cycle

        // LDI R2, 0xAB
        instruction = {4'h4, 4'h3, 8'hAB};

        tick(); tick(); tick(); tick(); tick();

        force r2 = 2'b01;  // whatever value makes register_file output R0
        #1;                // settle
        
        $display("2. rf_out_bus = %h", rf_out_bus);

        check(rf_out_bus == 16'h00AB,
            "LDI loads immediate 0x00AB into R2");
        release r2;  

        

        


        $display("\n╔══════════════════════════════════════════════╗");
        $display("║ Results: %0d passed, %0d failed             ║", pass, fail);
        $display("╚══════════════════════════════════════════════╝");

        $finish;
    end

endmodule