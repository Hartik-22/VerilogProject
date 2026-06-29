`timescale 1ns / 1ps

module voter_input_interface(

    input clk,
    input reset,

    input enter_button,
    input [15:0] entered_id,

    output reg [15:0] voter_id,
    output reg voter_valid
);

always @(posedge clk or posedge reset) begin

    if(reset) begin

        voter_id <= 16'd0;
        voter_valid <= 1'b0;
    end

    else begin

        voter_valid <= 1'b0;

        if(enter_button) begin

            voter_id <= entered_id;
            voter_valid <= 1'b1;
        end
    end
end

endmodule