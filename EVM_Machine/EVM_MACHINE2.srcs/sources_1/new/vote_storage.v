`timescale 1ns / 1ps

module vote_storage(

    input clk,
    input reset,

    input vote_enable,

    input [1:0] vote_input,

    output reg [15:0] BJP_votes,
    output reg [15:0] INC_votes,
    output reg [15:0] AAP_votes,
    output reg [15:0] SP_votes
);

always @(posedge clk or posedge reset) begin

    if(reset) begin

        BJP_votes <= 0;
        INC_votes <= 0;
        AAP_votes <= 0;
        SP_votes <= 0;
    end

    else begin

        if(vote_enable) begin

            case(vote_input)

                //////////////////////////////////////////////////
                // BJP
                //////////////////////////////////////////////////

                2'b00: begin

                    BJP_votes <= BJP_votes + 1;

                    $display("--------------------------------");
                    $display("Vote Casted -> BJP");
                end

                //////////////////////////////////////////////////
                // INC
                //////////////////////////////////////////////////

                2'b01: begin

                    INC_votes <= INC_votes + 1;

                    $display("--------------------------------");
                    $display("Vote Casted -> INC");
                end

                //////////////////////////////////////////////////
                // AAP
                //////////////////////////////////////////////////

                2'b10: begin

                    AAP_votes <= AAP_votes + 1;

                    $display("--------------------------------");
                    $display("Vote Casted -> AAP");
                end

                //////////////////////////////////////////////////
                // SP
                //////////////////////////////////////////////////

                2'b11: begin

                    SP_votes <= SP_votes + 1;

                    $display("--------------------------------");
                    $display("Vote Casted -> SP");
                end

            endcase
        end
    end
end

endmodule


