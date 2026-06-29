`timescale 1ns / 1ps

module vote_input_interface(

    input bjp_button,
    input inc_button,
    input aap_button,
    input sp_button,

    output reg [1:0] vote_input,
    output reg vote_valid
);

always @(*) begin

    vote_valid = 0;
    vote_input = 2'b00;

    if(bjp_button) begin

        vote_input = 2'b00;
        vote_valid = 1;
    end

    else if(inc_button) begin

        vote_input = 2'b01;
        vote_valid = 1;
    end

    else if(aap_button) begin

        vote_input = 2'b10;
        vote_valid = 1;
    end

    else if(sp_button) begin

        vote_input = 2'b11;
        vote_valid = 1;
    end
end

endmodule