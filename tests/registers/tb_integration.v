`timescale 1ns / 1ps

module tb_integration;

    // -------------------------
    // Testbench Signals
    // -------------------------
    reg         clk;
    reg         rst;
    reg  [5:0]  control_plane;
    reg  [15:0] immediate;

    wire [15:0] shared_bus;
    wire        bus_en;        // ← now driven by register_file output

    // -------------------------
    // DUT Instantiations
    // -------------------------
    register_file rf (
        .clk           (clk),
        .rst           (rst),
        .control_plane (control_plane),
        .input_bus     (shared_bus),
        .output_bus    (shared_bus),
        .bus_en        (bus_en)       // ← register file tells mux when to release
    );

    bus_mux mux (
        .immediate (immediate),
        .bus_en    (bus_en),           // ← wired directly from register_file
        .bus_out   (shared_bus)
    );

    // -------------------------
    // Control plane aliases
    // -------------------------
    localparam R1_LOAD = 6'b100000;
    localparam R1_OUT  = 6'b010000;
    localparam R2_LOAD = 6'b001000;
    localparam R2_OUT  = 6'b000100;
    localparam R3_LOAD = 6'b000010;
    localparam R3_OUT  = 6'b000001;

    // -------------------------
    // Clock
    // -------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check;
        input [15:0] expected;
        input        expect_hiz;
        input [63:0] test_num;
        begin
            if (expect_hiz) begin
                if (^shared_bus === 1'bx)
                    $display("PASS [Test %0d] shared_bus is Hi-Z", test_num);
                else
                    $display("FAIL [Test %0d] expected Hi-Z, got %0h", test_num, shared_bus);
            end else begin
                if (shared_bus === expected)
                    $display("PASS [Test %0d] shared_bus = %0h", test_num, shared_bus);
                else
                    $display("FAIL [Test %0d] expected %0h, got %0h", test_num, expected, shared_bus);
            end
        end
    endtask

    // -------------------------
    // Stimulus
    // -------------------------
    initial begin
        rst           = 1;
        immediate     = 16'h0000;
        control_plane = 6'b000000;
        // Note: bus_en is no longer set here — it's automatic from register_file

        // --------------------------------------------------
        // Test 1: Reset — all registers cleared
        // bus_en=0 so mux drives Hi-Z, registers drive 0 via tristate
        // --------------------------------------------------
        $display("--- Test 1: Reset ---");
        tick; tick;
        rst = 0;
        control_plane = R1_OUT; #2; check(16'h0000, 0, 1); control_plane = 6'b0; #2;
        control_plane = R2_OUT; #2; check(16'h0000, 0, 1); control_plane = 6'b0; #2;
        control_plane = R3_OUT; #2; check(16'h0000, 0, 1); control_plane = 6'b0; #2;

        // --------------------------------------------------
        // Test 2: Load 0xAAAA into R1
        // bus_en goes LOW (no tri active), mux drives immediate onto shared_bus
        // --------------------------------------------------
        $display("--- Test 2: Load 0xAAAA into R1 ---");
        immediate     = 16'hAAAA;
        control_plane = R1_LOAD;  // bus_en=0 automatically, mux drives immediate
        tick;
        control_plane = 6'b000000;

        // --------------------------------------------------
        // Test 3: Read R1
        // --------------------------------------------------
        $display("--- Test 3: Read R1 (expect 0xAAAA) ---");
        control_plane = R1_OUT;   // bus_en=1 automatically, mux goes Hi-Z
        #2;
        check(16'hAAAA, 0, 3);
        control_plane = 6'b000000;

        // --------------------------------------------------
        // Test 4: Load 0x1234 into R2
        // --------------------------------------------------
        $display("--- Test 4: Load 0x1234 into R2 ---");
        immediate     = 16'h1234;
        control_plane = R2_LOAD;
        tick;
        control_plane = 6'b000000;

        // --------------------------------------------------
        // Test 5: Read R2
        // --------------------------------------------------
        $display("--- Test 5: Read R2 (expect 0x1234) ---");
        control_plane = R2_OUT;
        #2;
        check(16'h1234, 0, 5);
        control_plane = 6'b000000;

        // --------------------------------------------------
        // Test 6: Load 0x5678 into R3
        // --------------------------------------------------
        $display("--- Test 6: Load 0x5678 into R3 ---");
        immediate     = 16'h5678;
        control_plane = R3_LOAD;
        tick;
        control_plane = 6'b000000;

        // --------------------------------------------------
        // Test 7: Read R3
        // --------------------------------------------------
        $display("--- Test 7: Read R3 (expect 0x5678) ---");
        control_plane = R3_OUT;
        #2;
        check(16'h5678, 0, 7);
        control_plane = 6'b000000;

        // --------------------------------------------------
        // Test 8: Register-to-register transfer R1 -> R2
        // R1_tri=1 so bus_en=1, mux releases, R1 drives bus, R2 latches
        // --------------------------------------------------
        $display("--- Test 8: R1 -> R2 transfer ---");
        immediate = 16'hAAAA; control_plane = R1_LOAD; tick;
        control_plane = 6'b000000; #2;
        control_plane = R1_OUT | R2_LOAD; // bus_en auto-high, mux releases
        tick;
        control_plane = 6'b000000; #2;
        control_plane = R2_OUT; #2; check(16'hAAAA, 0, 8); control_plane = 6'b0; #2;
        control_plane = R1_OUT; #2; check(16'hAAAA, 0, 8); control_plane = 6'b0;

        // --------------------------------------------------
        // Test 9: Broadcast immediate to all registers
        // --------------------------------------------------
        $display("--- Test 9: Broadcast 0xBEEF to all registers ---");
        immediate     = 16'hBEEF;
        control_plane = R1_LOAD | R2_LOAD | R3_LOAD; // bus_en=0, mux drives
        tick;
        control_plane = 6'b000000; #2;
        control_plane = R1_OUT; #2; check(16'hBEEF, 0, 9); control_plane = 6'b0; #2;
        control_plane = R2_OUT; #2; check(16'hBEEF, 0, 9); control_plane = 6'b0; #2;
        control_plane = R3_OUT; #2; check(16'hBEEF, 0, 9); control_plane = 6'b0;

        // --------------------------------------------------
        // Test 10: Mid-operation reset
        // --------------------------------------------------
        $display("--- Test 10: Mid-operation reset ---");
        immediate = 16'hDEAD; control_plane = R1_LOAD | R2_LOAD; tick;
        control_plane = 6'b000000;
        rst = 1; tick; rst = 0;
        control_plane = R1_OUT; #2; check(16'h0000, 0, 10); control_plane = 6'b0; #2;
        control_plane = R2_OUT; #2; check(16'h0000, 0, 10); control_plane = 6'b0; #2;
        control_plane = R3_OUT; #2; check(16'h0000, 0, 10); control_plane = 6'b0;

        // --------------------------------------------------
        // Test 11: Register independence
        // --------------------------------------------------
        $display("--- Test 11: Register independence ---");
        immediate = 16'hAABB; control_plane = R1_LOAD; tick; control_plane = 6'b0; #2;
        immediate = 16'hCCDD; control_plane = R2_LOAD; tick; control_plane = 6'b0; #2;
        immediate = 16'hEEFF; control_plane = R3_LOAD; tick; control_plane = 6'b0; #2;
        control_plane = R1_OUT; #2; check(16'hAABB, 0, 11); control_plane = 6'b0; #2;
        control_plane = R2_OUT; #2; check(16'hCCDD, 0, 11); control_plane = 6'b0; #2;
        control_plane = R3_OUT; #2; check(16'hEEFF, 0, 11); control_plane = 6'b0;

        // --------------------------------------------------
        // Test 12: Bus contention — two registers output simultaneously
        // --------------------------------------------------
        $display("--- Test 12: Bus contention (R1 + R2 tri simultaneously) ---");
        control_plane = R1_OUT | R2_OUT;
        #2;
        $display("INFO [Test 12] Contention result (expect X): %0h", shared_bus);
        control_plane = 6'b000000;

        #20;
        $display("Integration testbench complete.");
        $finish;
    end

    initial begin
        $dumpfile("tb_integration.vcd");
        $dumpvars(0, tb_integration);
    end

endmodule