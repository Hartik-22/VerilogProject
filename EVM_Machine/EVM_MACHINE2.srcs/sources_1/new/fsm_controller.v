`timescale 1ns / 1ps

module fsm_controller(

    input clk,
    input reset,

    input auth_done,
    input auth_success,
    input auth_fail,
    input already_voted,

    input vote_valid,

    output reg vote_enable,

    output reg [2:0] state
);

//////////////////////////////////////////////////////
// STATES
//////////////////////////////////////////////////////

parameter IDLE          = 3'b000;
parameter AUTH_CHECK    = 3'b001;
parameter WAIT_FOR_VOTE = 3'b010;
parameter VOTING        = 3'b011;
parameter ERROR_STATE   = 3'b100;

reg [2:0] next_state;

//////////////////////////////////////////////////////
// STATE REGISTER
//////////////////////////////////////////////////////

always @(posedge clk or posedge reset) begin

    if(reset)
        state <= IDLE;

    else
        state <= next_state;
end

//////////////////////////////////////////////////////
// NEXT STATE LOGIC
//////////////////////////////////////////////////////

always @(*) begin

    next_state = state;

    case(state)

        //////////////////////////////////////////////////
        // IDLE
        //////////////////////////////////////////////////

        IDLE: begin

            if(auth_done)
                next_state = AUTH_CHECK;
        end

        //////////////////////////////////////////////////
        // AUTH CHECK
        //////////////////////////////////////////////////

        AUTH_CHECK: begin

            if(auth_success)
                next_state = WAIT_FOR_VOTE;

            else if(auth_fail || already_voted)
                next_state = ERROR_STATE;
        end

        //////////////////////////////////////////////////
        // WAIT FOR VOTE
        //////////////////////////////////////////////////

        WAIT_FOR_VOTE: begin

            if(vote_valid)
                next_state = VOTING;
        end

        //////////////////////////////////////////////////
        // VOTING
        //////////////////////////////////////////////////

        VOTING: begin

            next_state = IDLE;
        end

        //////////////////////////////////////////////////
        // ERROR STATE
        //////////////////////////////////////////////////

        ERROR_STATE: begin

            next_state = IDLE;
        end

        default:
            next_state = IDLE;

    endcase
end

//////////////////////////////////////////////////////
// OUTPUT LOGIC
//////////////////////////////////////////////////////

always @(*) begin

    vote_enable = 0;

    case(state)

        VOTING: begin

            vote_enable = 1;
        end

    endcase
end

endmodule