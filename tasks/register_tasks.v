/*
This sets the switches on for the control plane.
*/
task get_register;
    input  [3:0]  rx;
    input         is_output;
    input  [23:0] curr_control_plane;    // was [19:5]
    output reg [23:0] output_control_plane;  // was [19:5]
    begin
        `include "../constants.v"
        output_control_plane = curr_control_plane;
        case (rx)
        `R0: begin
            $display("Store! Output = %b", is_output);
            $display("Output CP before = %b", output_control_plane);
            if (!is_output) output_control_plane[19] = 1'b1; // Stores
            else           output_control_plane[18] = 1'b1;  // Outputs
            $display("Output CP after = %b", output_control_plane);
        end
        `R1: begin
            if (!is_output) output_control_plane[17] = 1'b1; // Stores
            else           output_control_plane[16] = 1'b1; // Outputs
        end
        `R2: begin
            if (!is_output) output_control_plane[15] = 1'b1; // Stores
            else           output_control_plane[14] = 1'b1; // Outputs
        end
        `A: begin
            if (!is_output) output_control_plane[13] = 1'b1; // Stores
            else           output_control_plane[12] = 1'b1; // Outputs -- NOT USED!!!
        end
        `G: begin
            if (!is_output) output_control_plane[11] = 1'b1; // Stores
            else           output_control_plane[10] = 1'b1; // Outputs
        end
        endcase
    end

endtask