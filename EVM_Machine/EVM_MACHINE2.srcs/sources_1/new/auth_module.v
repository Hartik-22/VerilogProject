`timescale 1ns / 1ps

module auth_module(

    input clk,
    input reset,

    input [15:0] voter_id,
    input voter_valid,

    input vote_cast,

    output reg auth_done,
    output reg auth_success,
    output reg auth_fail,
    output reg already_voted
);

integer i;

reg found;

reg [15:0] valid_ids [0:9];
reg voted [0:9];

//////////////////////////////////////////////////////
// INITIAL DATABASE
//////////////////////////////////////////////////////

initial begin

    valid_ids[0] = 16'd1021;
    valid_ids[1] = 16'd2045;
    valid_ids[2] = 16'd3098;
    valid_ids[3] = 16'd4112;
    valid_ids[4] = 16'd5234;

    valid_ids[5] = 16'd6345;
    valid_ids[6] = 16'd7456;
    valid_ids[7] = 16'd8567;
    valid_ids[8] = 16'd9123;
    valid_ids[9] = 16'd9999;

    for(i=0;i<10;i=i+1)
        voted[i] = 0;
end

//////////////////////////////////////////////////////
// AUTH LOGIC
//////////////////////////////////////////////////////

always @(posedge clk or posedge reset) begin

    if(reset) begin

        auth_done <= 0;
        auth_success <= 0;
        auth_fail <= 0;
        already_voted <= 0;
    end

    else begin

        auth_done <= 0;
        auth_success <= 0;
        auth_fail <= 0;
        already_voted <= 0;

        found = 0;

        if(voter_valid) begin

            auth_done <= 1;

            for(i=0;i<10;i=i+1) begin

                if(voter_id == valid_ids[i]) begin
                    $display("Valid Voter ID = %d", voter_id);
                    found = 1;

                    if(voted[i]) begin

                        already_voted <= 1;
                    end

                    else begin

                        auth_success <= 1;

                        if(vote_cast)
                            voted[i] <= 1;
                    end
                end
            end

            if(found == 0)
                begin
                auth_fail <= 1;
                $display("INVALID VOTER ID = %d", voter_id);
                end
        end
    end
end

endmodule