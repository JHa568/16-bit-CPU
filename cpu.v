module cpu (

);
    reg [15:0] bus; // Used to communicate with other components. 
    reg [1:0] r0;
    reg [1:0] r1;
    reg [1:0] r2;
    reg [1:0] A;
    reg [4:0] S;
    reg [1:0] G;

    reg clk;

    initial begin
        clk = 0;
        bus = 16'd0;
        r0 = 2'd0;
        r1 = 2'd0;
        r2 = 2'd0;
        A = 2'd0;
        S = 2'd0;
        G = 2'd0;
    end
    
    always #10 clk = ~clk; 
endmodule