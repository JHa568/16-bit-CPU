always @(posedge clk or posedge reset) begin
    if (reset) begin
        PC <= 16'd0;
    end else begin
        case (opcode)
            // --- Unconditional Jump ---
            4'b0100: begin 
                PC <= imm; // Jump instantly. No "if" required.
            end

            // --- Conditional Branch (BEQ) ---
            4'b0101: begin
                if (alu_status[3]) // alu_status[3] is the ZERO flag
                    PC <= imm;     // If zero, jump to the address
                else
                    PC <= PC + 1;  // If not zero, just go to the next line
            end

            // --- Other instructions (ADD, SUB, etc.) ---
            default: PC <= PC + 1;
        endcase
    end
end