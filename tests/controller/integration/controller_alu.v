module controller_alu;
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

    integer pass = 0;
    integer fail = 0;

    ALU_component alu (
        .clk(clk),
        .rst(1'b0),
        .alu_ctl(ALU),
        .control_plane({A, G}),
        .input_bus(bus),
        .output_bus(alu_bus)
    );
    
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
        .immediate (imm_bus),
        .alu       (alu_bus),
        .registers (reg_bus),
        .bus_sel   (bus_sel),
        .bus_out   (bus)
    );

    register_file rf (
        .clk(clk),
        .rst(1'b0),
        .control_plane({r0, r1, r2}),
        .input_bus(bus),
        .output_bus(reg_bus)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            #10;
        end
    endtask

    task check;
        input [63:0] cond;
        input [127:0] msg;
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
        $dumpfile("alu.vcd");
        $dumpvars(0, controller_alu);
        $display("\n╔══════════════════════════════════════════════╗");
        $display("║              ALU Integration Suite          ║");
        $display("╚══════════════════════════════════════════════╝");

        clk = 0;
        status_register = 0;

        // ═══════════════════════════════════════════════
        // TEST 1: ADD — 0x0005 + 0x0003 = 0x0008
        // ═══════════════════════════════════════════════
        $display("\n[TEST 1] ADD: 0x0005 + 0x0003 = 0x0008");

        // Step 1a: LDI R0, 0x05  (first operand into R0)
        instruction = {`LDI, `R0, 8'h05};
        tick(); tick(); tick(); tick(); tick();

        // Step 1c: LDI R1, 0x03  (second operand, will be on bus during ALU compute)
        instruction = {`LDI, `R1, 8'h03};
        tick(); tick(); tick(); tick(); tick();

        $display("------------------ BEGIN ADD -------------------");
        instruction = {`ADD, `R0, `R1, 4'h0};
        tick(); tick(); tick(); tick(); tick();

        // Step 1e: Read G onto bus
        force G = 2'b01;   // G_en=0, G_tri=1 (G drives output_bus)
        #1;
        $display("  alu_bus = %h", alu_bus);
        check(alu_bus == 16'h0008, "ADD 0x0005 + 0x0003 = 0x0008");
        release G;
        release A;

        // ═══════════════════════════════════════════════
        // TEST 2: ADD with carry boundary — 0x00FF + 0x0001 = 0x0100
        // ═══════════════════════════════════════════════
        $display("\n[TEST 2] ADD boundary: 0x00FF + 0x0001 = 0x0100");

        instruction = {`LDI, `R0, 8'hFF};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`LDI, `R1, 8'h01};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`ADD, `R0, `R1, 4'h0};
        tick(); tick(); tick(); tick(); tick();

        force G = 2'b01;
        #1;
        $display("  alu_bus = %h", alu_bus);
        check(alu_bus == 16'h0100, "ADD 0x00FF + 0x0001 = 0x0100");
        release G; release A;

        // ═══════════════════════════════════════════════
        // TEST 3: SUB — 0x000A - 0x0003 = 0x0007
        // ═══════════════════════════════════════════════
        $display("\n[TEST 3] SUB: 0x000A - 0x0003 = 0x0007");

        instruction = {`LDI, `R0, 8'h0A};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`LDI, `R1, 8'h03};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`SUB, `R0, `R1, 4'h0};
        tick(); tick(); tick(); tick(); tick();

        force G = 2'b01;
        #1;
        $display("  alu_bus = %h", alu_bus);
        check(alu_bus == 16'h0007, "SUB 0x000A - 0x0003 = 0x0007");
        release G; release A;

        // ═══════════════════════════════════════════════
        // TEST 4: SUB underflow — 0x0000 - 0x0001 = 0xFFFF
        // ═══════════════════════════════════════════════
        $display("\n[TEST 4] SUB underflow: 0x0000 - 0x0001 = 0xFFFF");

        instruction = {`LDI, `R0, 8'h00};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`LDI, `R1, 8'h01};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`SUB, `R0, `R1, 4'h0};
        tick(); tick(); tick(); tick(); tick();

        force G = 2'b01;
        #1;
        $display("  alu_bus = %h", alu_bus);
        check(alu_bus == 16'hFFFF, "SUB 0x0000 - 0x0001 = 0xFFFF (underflow)");
        release G; release A;

        // ═══════════════════════════════════════════════
        // TEST 5: ADD zero identity — 0x00AB + 0x0000 = 0x00AB
        // ═══════════════════════════════════════════════
        $display("\n[TEST 5] ADD zero identity: 0x00AB + 0x0000 = 0x00AB");

        instruction = {`LDI, `R0, 8'hAB};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`LDI, `R1, 8'h00};
        tick(); tick(); tick(); tick(); tick();

        instruction = {`ADD, `R0, `R1, 4'h0};
        tick(); tick(); tick(); tick(); tick();

        force G = 2'b01;
        #1;
        $display("  alu_bus = %h", alu_bus);
        check(alu_bus == 16'h00AB, "ADD 0x00AB + 0x0000 = 0x00AB (identity)");
        release G; release A;

        $display("\n╔══════════════════════════════════════════════╗");
        $display("║ Results: %0d passed, %0d failed             ║", pass, fail);
        $display("╚══════════════════════════════════════════════╝");
        $finish;
    end
endmodule 