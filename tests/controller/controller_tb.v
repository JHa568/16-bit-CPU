`timescale 1ns / 1ps

module controller_tb;

    // ------------------------------------------------------------
    // Local opcode / register encodings
    // ------------------------------------------------------------
    localparam [3:0] OP_ADD = 4'b0001;
    localparam [3:0] OP_SUB = 4'b0010;
    localparam [3:0] OP_MOV = 4'b0011;
    localparam [3:0] OP_LDI = 4'b0100;

    localparam [1:0] REG_R0 = 2'b01;
    localparam [1:0] REG_R1 = 2'b10;
    localparam [1:0] REG_R2 = 2'b11;

    // ------------------------------------------------------------
    // DUT inputs
    // ------------------------------------------------------------
    reg clk;
    reg status_register;
    reg [15:0] instruction;
    reg [15:0] curr_comm_bus;

    // ------------------------------------------------------------
    // DUT outputs
    // ------------------------------------------------------------
    wire [1:0] r0;
    wire [1:0] r1;
    wire [1:0] r2;
    wire [1:0] A;
    wire [3:0] ALU;
    wire [4:0] SR;
    wire [1:0] G;
    wire bus_en;
    wire [15:0] out_comm_bus;

    // ------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------
    controller_fsm dut (
        .clk(clk),
        .status_register(status_register),
        .instruction(instruction),
        .curr_comm_bus(curr_comm_bus),
        .r0(r0),
        .r1(r1),
        .r2(r2),
        .A(A),
        .ALU(ALU),
        .SR(SR),
        .G(G),
        .bus_en(bus_en),
        .out_comm_bus(out_comm_bus)
    );

    // ------------------------------------------------------------
    // Test counters
    // ------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_id;

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------
    task tick;
    begin
        @(posedge clk);
        #1; // allow DUT outputs to settle
    end
    endtask

    task banner;
    begin
        $display("");
        $display("╔══════════════════════════════════════════════╗");
        $display("║       controller_fsm Integration Suite       ║");
        $display("╚══════════════════════════════════════════════╝");
        $display("");
    end
    endtask

    task check_ctrl;
        input [8*32-1:0] name;
        input exp_bus_en;
        input [1:0] exp_r0;
        input [1:0] exp_r1;
        input [1:0] exp_r2;
        input [1:0] exp_A;
        input [1:0] exp_G;
        input [3:0] exp_ALU;
        input [4:0] exp_SR;
        reg ok;
    begin
        test_id = test_id + 1;

        ok =
            (bus_en === exp_bus_en) &&
            (r0     === exp_r0)     &&
            (r1     === exp_r1)     &&
            (r2     === exp_r2)     &&
            (A      === exp_A)      &&
            (G      === exp_G)      &&
            (ALU    === exp_ALU)    &&
            (SR     === exp_SR);

        if (ok) begin
            pass_count = pass_count + 1;
            $display("  [PASS] T%-2d  %-18s r0=%b r1=%b r2=%b A=%b G=%b ALU=%b SR=%b",
                     test_id, name, r0, r1, r2, A, G, ALU, SR);
        end
        else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] T%-2d  %-18s got r0=%b r1=%b r2=%b A=%b G=%b ALU=%b SR=%b",
                     test_id, name, r0, r1, r2, A, G, ALU, SR);
            $display("                        exp r0=%b r1=%b r2=%b A=%b G=%b ALU=%b SR=%b",
                     exp_r0, exp_r1, exp_r2, exp_A, exp_G, exp_ALU, exp_SR);
        end
    end
    endtask

    task check_ctrl_bus;
        input [8*32-1:0] name;
        input exp_bus_en;
        input [1:0] exp_r0;
        input [1:0] exp_r1;
        input [1:0] exp_r2;
        input [1:0] exp_A;
        input [1:0] exp_G;
        input [3:0] exp_ALU;
        input [4:0] exp_SR;
        input [15:0] exp_out_bus;
        reg ok;
    begin
        test_id = test_id + 1;

        ok =
            (bus_en      === exp_bus_en) &&
            (r0          === exp_r0)     &&
            (r1          === exp_r1)     &&
            (r2          === exp_r2)     &&
            (A           === exp_A)      &&
            (G           === exp_G)      &&
            (ALU         === exp_ALU)    &&
            (SR          === exp_SR)     &&
            (out_comm_bus=== exp_out_bus);

        if (ok) begin
            pass_count = pass_count + 1;
            $display("  [PASS] T%-2d  %-18s r0=%b r1=%b r2=%b A=%b G=%b ALU=%b SR=%b bus=%h",
                     test_id, name, r0, r1, r2, A, G, ALU, SR, out_comm_bus);
        end
        else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] T%-2d  %-18s got r0=%b r1=%b r2=%b A=%b G=%b ALU=%b SR=%b bus=%h",
                     test_id, name, r0, r1, r2, A, G, ALU, SR, out_comm_bus);
            $display("                        exp r0=%b r1=%b r2=%b A=%b G=%b ALU=%b SR=%b bus=%h",
                     exp_r0, exp_r1, exp_r2, exp_A, exp_G, exp_ALU, exp_SR, exp_out_bus);
        end
    end
    endtask

    // ------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------
    initial begin
        $dumpfile("controller_tb.vcd");
        $dumpvars(0, controller_tb);

        pass_count = 0;
        fail_count = 0;
        test_id    = 0;

        status_register = 1'b0;
        curr_comm_bus   = 16'h0000;
        instruction     = 16'h0000;

        banner();

        // --------------------------------------------------------
        // ADD R0, R1
        // opcode=ADD, Rx=R0, Ry=R1
        // --------------------------------------------------------
        $display("── ADD R0, R1 ─────────────────────────────────");
        instruction = {OP_ADD, REG_R0, REG_R1, 8'h00};

        tick; check_ctrl("ADD FETCH",    1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("ADD DECODE",   1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("ADD LOAD",     1'b0, 2'b10, 2'b00, 2'b00, 2'b01, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("ADD EXECUTE",  1'b0, 2'b00, 2'b10, 2'b00, 2'b00, 2'b01, OP_ADD,  5'b00000);
        tick; check_ctrl("ADD WRITEBACK", 1'b0, 2'b01, 2'b00, 2'b00, 2'b00, 2'b10, 4'b0000, 5'b00000);

        // --------------------------------------------------------
        // SUB R2, R0
        // opcode=SUB, Rx=R2, Ry=R0
        // --------------------------------------------------------
        $display("");
        $display("── SUB R2, R0 ─────────────────────────────────");
        instruction = {OP_SUB, REG_R2, REG_R0, 8'h00};

        tick; check_ctrl("SUB FETCH",    1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("SUB DECODE",   1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("SUB LOAD",     1'b0, 2'b00, 2'b00, 2'b10, 2'b01, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("SUB EXECUTE",  1'b0, 2'b10, 2'b00, 2'b00, 2'b00, 2'b01, OP_SUB,  5'b00000);
        tick; check_ctrl("SUB WRITEBACK", 1'b0, 2'b00, 2'b00, 2'b01, 2'b00, 2'b10, 4'b0000, 5'b00000);

        // --------------------------------------------------------
        // MOV R1, R2
        // opcode=MOV, Rx=R1 (source), Ry=R2 (dest)
        // --------------------------------------------------------
        $display("");
        $display("── MOV R1, R2 ─────────────────────────────────");
        instruction = {OP_MOV, REG_R1, REG_R2, 8'h00};

        tick; check_ctrl("MOV FETCH",    1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("MOV DECODE",   1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("MOV LOAD",     1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("MOV EXECUTE",  1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("MOV WRITEBACK", 1'b0, 2'b10, 2'b00, 2'b01, 2'b00, 2'b00, 4'b0000, 5'b00000);

        // --------------------------------------------------------
        // LDI R0, 0xD
        // opcode=LDI, Rx=R0, D=1101
        // --------------------------------------------------------
        $display("");
        $display("── LDI R0, 0xD ────────────────────────────────");
        instruction = {OP_LDI, REG_R0, 4'b1101, 6'b000000};

        tick; check_ctrl("LDI FETCH",    1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("LDI DECODE",   1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("LDI LOAD",     1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("LDI EXECUTE",  1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl_bus("LDI WRITEBACK", 1'b1, 2'b01, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000, 16'h000D);

        // --------------------------------------------------------
        // Invalid opcode
        // --------------------------------------------------------
        $display("");
        $display("── Invalid opcode ─────────────────────────────");
        instruction = {4'hF, 12'h000};

        tick; check_ctrl("INV FETCH",    1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("INV DECODE",   1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("INV LOAD",     1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("INV EXECUTE",  1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("INV WRITEBACK",1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);

        // --------------------------------------------------------
        // Back-to-back behavior
        // --------------------------------------------------------
        $display("");
        $display("── Back-to-back instruction flow ──────────────");
        instruction = {OP_ADD, REG_R1, REG_R2, 8'h00};
        tick; check_ctrl("BB ADD FETCH",    1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("BB ADD DECODE",   1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("BB ADD LOAD",     1'b0, 2'b10, 2'b00, 2'b00, 2'b01, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("BB ADD EXECUTE",  1'b0, 2'b00, 2'b10, 2'b00, 2'b00, 2'b01, OP_ADD,  5'b00000);
        tick; check_ctrl("BB ADD WRITEBACK", 1'b0, 2'b00, 2'b10, 2'b00, 2'b00, 2'b01, 4'b0000, 5'b00000);

        instruction = {OP_SUB, REG_R0, REG_R1, 8'h00};
        tick; check_ctrl("BB SUB FETCH",    1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("BB SUB DECODE",   1'b0, 2'b00, 2'b00, 2'b00, 2'b00, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("BB SUB LOAD",     1'b0, 2'b10, 2'b00, 2'b00, 2'b01, 2'b00, 4'b0000, 5'b00000);
        tick; check_ctrl("BB SUB EXECUTE",  1'b0, 2'b00, 2'b10, 2'b00, 2'b00, 2'b01, OP_SUB,  5'b00000);
        tick; check_ctrl("BB SUB WRITEBACK", 1'b0, 2'b01, 2'b00, 2'b00, 2'b00, 2'b10, 4'b0000, 5'b00000);

        // --------------------------------------------------------
        // Summary
        // --------------------------------------------------------
        $display("");
        $display("╔══════════════════════════════════════════════╗");
        $display("║  Results: %0d passed, %0d failed  (total %0d) ║",
                 pass_count, fail_count, pass_count + fail_count);
        $display("╚══════════════════════════════════════════════╝");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule