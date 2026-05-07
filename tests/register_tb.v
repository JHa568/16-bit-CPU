module register_tb();
    reg clk; 
    reg [15:0] counter; // Counter 
    reg rst; // Clear signal wire
    wire [15:0] out; 

    register_16bit register(
        .clk(clk),
        .clear(rst),
        .d(counter),
        .o(out)
    );

    initial begin
        $dumpfile("register.vcd");
        $dumpvars(0, register_tb);

        // Initialise them all to zero
        clk = 1'b0;
        rst = 1;
        #10;   
        rst = 0;
        counter = 16'd0;
        #20000;
        $finish;
    end
    
    always #5 clk = ~clk;

    always @(posedge clk or posedge rst) begin
        if (rst) begin 
            counter <= 0;
        end else begin 
            counter <= counter + 1;
        end
    end
endmodule 