`timescale 1ns / 1ps

// =============================================================
// pc.v
// -------------------------------------------------------------
// Program Counter.
//
// The PC stores the address of the instruction currently being
// fetched from instruction memory.
//
// Normal execution: PC increments by 1.
// Jump/branch:      PC loads a new address.
// Reset:            PC returns to address 0.
// =============================================================

module pc(
    input             clk,
    input             rst,
    input             pc_en,    // Increment PC when high
    input             pc_load,  // Load pc_in when high
    input      [7:0]  pc_in,    // Branch/jump target address
    output reg [7:0]  pc_out    // Current instruction address
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 8'd0;
        end
        else if (pc_load) begin
            pc_out <= pc_in;
        end
        else if (pc_en) begin
            pc_out <= pc_out + 8'd1;
        end
    end

endmodule
