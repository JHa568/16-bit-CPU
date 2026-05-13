module register_tb();
    // -------------------------
    // Testbench Signals
    // -------------------------
    reg         clk;
    reg         rst;
    reg         R1_en;
    reg         R1_tri;      // separate tristate control
    reg  [15:0] counter;
    wire [15:0] output_bus;

    // -------------------------
    // DUT Instantiation
    // -------------------------
    register_16bit register(
        .clk   (clk),
        .rst   (rst),
        .load  (R1_en),
        .o_en  (R1_tri),     // driven independently
        .d     (counter),
        .o     (output_bus)
    );

    // -------------------------
    // Clock Generation: 10ns period
    // -------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------
    // Task: Apply one clock cycle
    // -------------------------
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // -------------------------
    // Task: Check output_bus value or hi-Z
    // -------------------------
    task check;
        input [15:0] expected;
        input        expect_hiz;
        input [63:0] test_num;
        begin
            if (expect_hiz) begin
                if (^output_bus === 1'bx)
                    $display("PASS [Test %0d] output_bus is Hi-Z as expected", test_num);
                else
                    $display("FAIL [Test %0d] expected Hi-Z, got %0h", test_num, output_bus);
            end else begin
                if (output_bus === expected)
                    $display("PASS [Test %0d] output_bus = %0h", test_num, output_bus);
                else
                    $display("FAIL [Test %0d] expected %0h, got %0h", test_num, expected, output_bus);
            end
        end
    endtask

    // -------------------------
    // Stimulus
    // -------------------------
    initial begin
        // Initialise
        rst     = 1;
        R1_en   = 0;
        R1_tri  = 0;
        counter = 16'h0000;

        // --------------------------------------------------
        // Test 1: Reset, both controls low -> Hi-Z
        // --------------------------------------------------
        tick; tick;
        check(16'hxxxx, 1, 1);

        // --------------------------------------------------
        // Test 2: Release reset, neither load nor o_en asserted
        // --------------------------------------------------
        rst = 0;
        tick;
        check(16'hxxxx, 1, 2);

        // --------------------------------------------------
        // Test 3: Load a value WITHOUT enabling the output
        // Register latches data, bus stays Hi-Z
        // --------------------------------------------------
        counter = 16'hA5A5;
        R1_en   = 1;
        tick;                   // latch A5A5
        R1_en   = 0;
        check(16'hxxxx, 1, 3); // o_en still low, bus should be Hi-Z

        // --------------------------------------------------
        // Test 4: Now enable the tristate output
        // Should see the loaded value on the bus
        // --------------------------------------------------
        R1_tri = 1;
        #2;
        check(16'hA5A5, 0, 4);

        // --------------------------------------------------
        // Test 5: Disable tristate -> bus goes Hi-Z again
        // --------------------------------------------------
        R1_tri = 0;
        #2;
        check(16'hxxxx, 1, 5);

        // --------------------------------------------------
        // Test 6: Load new value while output is disabled
        // --------------------------------------------------
        counter = 16'hDEAD;
        R1_en   = 1;
        tick;
        R1_en   = 0;
        check(16'hxxxx, 1, 6); // still Hi-Z

        // Enable output to verify new value was latched
        R1_tri = 1;
        #2;
        check(16'hDEAD, 0, 6);

        // --------------------------------------------------
        // Test 7: Load and output simultaneously
        // --------------------------------------------------
        counter = 16'hBEEF;
        R1_en   = 1;
        tick;
        R1_en   = 0;
        check(16'hBEEF, 0, 7); // R1_tri still high

        // --------------------------------------------------
        // Test 8: Assert reset while output enabled -> clears to 0
        // --------------------------------------------------
        rst = 1;
        tick;
        check(16'h0000, 0, 8);
        rst = 0;

        // --------------------------------------------------
        // Test 9: All 1s
        // --------------------------------------------------
        counter = 16'hFFFF;
        R1_en   = 1;
        tick;
        R1_en   = 0;
        check(16'hFFFF, 0, 9);

        // --------------------------------------------------
        // Test 10: Walking-ones pattern
        // --------------------------------------------------
        begin : walking_ones
            integer i;
            for (i = 0; i < 16; i = i + 1) begin
                counter = (16'h0001 << i);
                R1_en   = 1;
                tick;
                R1_en   = 0;
                if (output_bus === counter)
                    $display("PASS [Test 10.%0d] Walking-one bit %0d = %0h", i, i, output_bus);
                else
                    $display("FAIL [Test 10.%0d] expected %0h, got %0h", i, counter, output_bus);
            end
        end

        // --------------------------------------------------
        // Done
        // --------------------------------------------------
        R1_tri = 0;
        #20;
        $display("Testbench complete.");
        $finish;
    end

    // -------------------------
    // Waveform dump
    // -------------------------
    initial begin
        $dumpfile("register_tb.vcd");
        $dumpvars(0, register_tb);
    end
endmodule 