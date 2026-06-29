module vvpat_module(

    input vote_enable,
    input [1:0] candidate
);

always @(*) begin

    if(vote_enable) begin

        case(candidate)

            2'b00:
            $display("VVPAT: Vote Casted to BJP (Lotus)");

            2'b01:
            $display("VVPAT: Vote Casted to INC (Hand)");

            2'b10:
            $display("VVPAT: Vote Casted to AAP (Broom)");

            2'b11:
            $display("VVPAT: Vote Casted to SP (Cycle)");

        endcase
    end
end

endmodule