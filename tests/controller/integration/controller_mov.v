`timescale 1ns / 1ps
`include "constants.v"

module controller_mov;
reg clk;
reg status_register;
reg [15:0] instruction;
wire [1:0] r0, r1, r2, A, G;
wire [3:0] ALU;
wire [4:0] SR;
wire [3:0] bus_sel;
wire [15:0] imm_bus;
wire [15:0] alu_bus;
wire [15:0] reg_bus;
wire [15:0] bus;
wire [15:0] rf_out_bus;
integer pass = 0;
integer fail = 0;

assign alu_bus = 16'b0;

controller_fsm dut (
    .clk(clk),
    .status_register(status_register),
    .instruction(instruction),
    .curr_comm_bus(bus),
    .r0(r0), .r1(r1), .r2(r2),
    .A(A),
    .ALU(ALU),
    .SR(SR),
    .G(G),
    .bus_sel(bus_sel),
    .out_comm_bus(imm_bus)
);

bus_mux mux (
    .immediate (imm_bus),
    .alu       (alu_bus),
    .registers (reg_bus),
    .bus_sel   (bus_sel),
    .bus_out   (bus)
);

register_file rf (
    .clk(clk),
    .rst(1'b0),
    .control_plane({r0, r1, r2}),
    .input_bus(bus),
    .output_bus(reg_bus)
);

always #5 clk = ~clk;

task tick;
begin
    #10;
end
endtask

task check;
input [63:0] cond;
input [127:0] msg;
begin
    if (cond) begin
        $display("  [PASS] %s", msg);
        pass = pass + 1;
    end else begin
        $display("  [FAIL] %s", msg);
        fail = fail + 1;
    end
end
endtask

initial begin
    $dumpfile("mov.vcd");
    $dumpvars(0, controller_mov);

    $display("\n╔══════════════════════════════════════════════╗");
    $display("║               MOV Integration Suite         ║");
    $display("╚══════════════════════════════════════════════╝");

    clk = 0;
    status_register = 0;

    // ─── Step 1: LDI R0, 0x0D (seed a value into R0 first) ───
    $display("\n[TEST SETUP] LDI R0, 0x0D");
    instruction = {`LDI, `R0, 8'h0D};
    tick(); // FETCH
    tick(); // DECODE
    tick(); // LOAD
    tick(); // EXECUTE
    tick(); // WRITEBACK

    // Verify R0 was loaded correctly before MOV
    force r0 = 2'b01;
    #1;
    $display("  setup: reg_bus (R0) = %h", reg_bus);
    check(reg_bus == 16'h000D, "SETUP: R0 contains 0x000D before MOV");
    release r0;

    // ─── Step 2: MOV R1, R0 (copy R0 into R1) ───
    $display("\n[TEST 1] MOV R0, R1");
    instruction = {`MOV, `R0, `R1, 4'b0000};
    tick(); // FETCH
    tick(); // DECODE
    tick(); // LOAD
    tick(); // EXECUTE
    tick(); // WRITEBACK

    // Read back R1 to verify it received R0's value
    force r1 = 2'b01;
    #1;
    $display("  rf_out_bus (R1) = %h", reg_bus);
    check(reg_bus == 16'h000D, "MOV R1, R0 copies 0x000D into R1");
    release r1;

    // ─── Step 3: Verify R0 unchanged after MOV ───
    $display("\n[TEST 2] R0 unchanged after MOV");
    force r0 = 2'b01;
    #1;
    $display("  rf_out_bus (R0) = %h", reg_bus);
    check(reg_bus == 16'h000D, "R0 still contains 0x000D after MOV");
    release r0;

    $display("\n╔══════════════════════════════════════════════╗");
    $display("║ Results: %0d passed, %0d failed             ║", pass, fail);
    $display("╚══════════════════════════════════════════════╝");
    $finish;
end
endmodule