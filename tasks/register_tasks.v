/* 
Used to activate which register to activate on the 
control plane.
*/

task get_register;
    input reg [1:0] rx; // register type to act upon.
    input reg is_output; // either output (1) or store (0).
    input reg [19:5] curr_control_plane; 
    output [19:5] output_control_plane;

    begin
        `include "../../constants.v";
        
        // This updates the current control plane.
        
        always @(rx or is_output);
        begin
            case(rx);
                `R0: begin 
                    if (is_output) begin
                        curr_control_plane[19] = 1'b1; 
                    end else begin
                        curr_control_plane[18] = 1'b1;
                    end
                end
                `R1: begin 
                    if (is_output) begin
                        curr_control_plane[17] = 1'b1; 
                    end else begin
                        curr_control_plane[16] = 1'b1;
                    end
                end
                `R2: begin 
                    if (is_output) begin
                        curr_control_plane[15] = 1'b1; 
                    end else begin
                        curr_control_plane[14] = 1'b1;
                    end
                end
                `A: begin 
                    if (is_output) begin
                        curr_control_plane[13] = 1'b1; 
                    end else begin
                        curr_control_plane[12] = 1'b1;
                    end
                end
                `G: begin 
                    if (is_output) begin
                        curr_control_plane[11] = 1'b1; 
                    end else begin
                        curr_control_plane[10] = 1'b1;
                    end
                end
            endcase
            output_control_plane <= curr_control_plane;
        end
    end
endtask