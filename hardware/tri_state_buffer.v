module tri_state_buffer(
    input enable,
    input [15:0] data,
    output [15:0] out
);
    // if not enabled disconnect the connection of the output
    // represents high impedance of the wire.
    assign out = enable ? data : 16'bz;
endmodule