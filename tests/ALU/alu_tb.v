module alu_tb();
    reg clk;
    reg counter;
    
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        // Initialise them all to zero
        clk = 1'b0;
        counter = 5'd0;
        #20000;
        $finish;
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin 
        counter <= counter + 1;
    end
    
endmodule