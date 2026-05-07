module addition_tb();
    reg         clk;
    reg  [4:0]  counter;
    reg  signed [15:0] a, b;   // signed to handle negative tests
    wire [15:0] result;
    wire [4:0]  status;

    ALU add_operation(
        .alu_ctl(`ADD),
        .a(a), .b(b),
        .result(result),
        .status(status)
    );

    initial begin
        $dumpfile("addition.vcd");
        $dumpvars(0, addition_tb);
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
            5'd1: begin a <= 16'd1;     b <= 16'd1;    end
            5'd2: begin a <= 16'hFFFF;  b <= 16'd1;    end  
            5'd3: begin a <= 16'hFFFF;  b <= 16'hFFFF; end
            5'd4: begin a <= 16'd15;    b <= 16'd37;   end
            5'd5: begin a <= 16'd37;    b <= 16'd15;   end
            5'd6: begin a <= -16'd15;   b <= 16'd37;   end  
            default: begin a <= 16'd0;  b <= 16'd0;    end
        endcase
    end

endmodule