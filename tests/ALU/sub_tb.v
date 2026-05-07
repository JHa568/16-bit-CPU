module subtraction_tb();
    reg         clk;
    reg  [4:0]  counter;
    reg  signed [15:0] a, b;   // signed to handle negative tests
    wire [15:0] result;
    wire [4:0]  status;

    ALU add_operation(
        .alu_ctl(`SUB),
        .a(a), .b(b),
        .result(result),
        .status(status)
    );

    initial begin
        $dumpfile("sub.vcd");
        $dumpvars(0, subtraction_tb);
        clk     = 1'b0;
        counter = 5'd0;
        a       = 16'd0;
        b       = 16'd0;
        #20000;
        $finish;
    end

    always #5 clk = ~clk;

    always @(posedge clk)
        counter <= counter + 1;

    always @(*) begin       
        case (counter)
            5'd1: begin a <= 16'd1;     b <= 16'd1;    end // Simple subtraction
            5'd2: begin a <= 16'd1;     b <= 16'd2;    end // simple underflow   
            5'd3: begin a <= 16'd1;     b <= 16'hFFFF; end // aggressive Underflow 
            5'd4: begin a <= 16'd15;    b <= 16'd37;   end // Simple subtraction (b > a) different numbers
            5'd5: begin a <= 16'd37;    b <= 16'd15;   end // Simple subtraction (a > b) different numbers
            5'd6: begin a <= -16'd15;   b <= 16'd37;   end // Simple subtraction negative numbers  
            default: begin a <= 16'd0;  b <= 16'd0;    end // Should not hit after test operations are done
        endcase
    end

endmodule