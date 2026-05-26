module stack_pointer(
    // Stack pointer control signals
    input       clk,
    input       rst,
    input       sp_push,
    input       sp_pop,
    input       use_sp_addr,
    input [7:0] imm8
);
    // ---------------------------------------------------------
    // Stack Pointer
    // Full-descending: starts at 0xFF (top of data memory)
    // PUSH: write to mem[SP], then SP--
    // POP:  SP++, then read from mem[SP]
    // ---------------------------------------------------------
    reg [7:0] SP;
    wire [7:0] dmem_addr; 

    always @(posedge clk or posedge rst) begin
        if (rst)
            SP <= 8'hFF;
        else if (sp_push)
            SP <= SP - 1'b1;
        else if (sp_pop)
            SP <= SP + 1'b1;
    end

    // Address mux: SP for stack operations, immediate for LOAD/STORE
    assign dmem_addr = use_sp_addr ? SP : imm8;

endmodule