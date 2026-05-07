module tri_state_buffer_tb();
    reg enable;
    reg clk;
    reg [4:0] counter;
    reg [15:0] bus;
    wire [15:0] o;

    tri_state_buffer buff(.enable(enable), .data(bus), .out(o));
    
    initial begin
        $dumpfile("tsb.vcd");
        $dumpvars(0, tri_state_buffer_tb);

        // Initialise them all to zero
        clk = 1'b0;
        enable = 1'b0;
        bus = 16'bx;
        counter = 5'd0;
        #20000;
        $finish;
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin 
        counter <= counter + 1;
    end

    always @(counter) begin
        if (counter[0] == 1'b1) begin // Store data
            bus <= counter;
            enable <= 1'b1;
        end else if (counter[2] == 1'b1) begin // Adding Junk Data
            bus <= $random;
            enable <= 1'b0;
        end else begin // Adding other invalid data
            bus <= 16'bx;
            enable <= 1'b0;
        end 
    end
endmodule