module evm_top(

    input clk,
    input reset,

    input enter_button,
    input [15:0] entered_id,

    input bjp_button,
    input inc_button,
    input aap_button,
    input sp_button,

    input [15:0] admin_password,
    input admin_valid,
    input admin_logout,

    output [15:0] BJP_votes,
    output [15:0] INC_votes,
    output [15:0] AAP_votes,
    output [15:0] SP_votes
);

//////////////////////////////////////////////////////
// INTERNAL SIGNALS
//////////////////////////////////////////////////////

wire [15:0] voter_id;
wire voter_valid;

wire auth_done;
wire auth_success;
wire auth_fail;
wire already_voted;

wire [1:0] vote_input;
wire vote_valid;

//wire vote_enable;


//wire [2:0] state;

wire admin_success;



wire [15:0] invalid_attempts;

wire led1,led2,led3,led4;

//////////////////////////////////////////////////////
// VOTER INPUT
//////////////////////////////////////////////////////

voter_input_interface INPUT_ID(

    .clk(clk),
    .reset(reset),

    .enter_button(enter_button),
    .entered_id(entered_id),

    .voter_id(voter_id),
    .voter_valid(voter_valid)
);

//////////////////////////////////////////////////////
// AUTH MODULE
//////////////////////////////////////////////////////

auth_module AUTH(

    .clk(clk),
    .reset(reset),

    .voter_id(voter_id),
    .voter_valid(voter_valid),

    .vote_cast(vote_valid),

    .auth_done(auth_done),
    .auth_success(auth_success),
    .auth_fail(auth_fail),
    .already_voted(already_voted)
);

//////////////////////////////////////////////////////
// VOTE INPUT
//////////////////////////////////////////////////////

vote_input_interface VOTE_INPUT(


    .bjp_button(bjp_button),
    .inc_button(inc_button),
    .aap_button(aap_button),
    .sp_button(sp_button),

    .vote_input(vote_input),
    .vote_valid(vote_valid)
);

//////////////////////////////////////////////////////
// ADMIN AUTH
//////////////////////////////////////////////////////

admin_auth ADMIN(

    .clk(clk),
    .reset(reset),

    .admin_password(admin_password),
    .admin_valid(admin_valid),

    .admin_logout(admin_logout),

    .admin_success(admin_success)
);


vote_storage STORE(

    .clk(clk),
    .reset(reset),

    .vote_enable(vote_valid),

    .vote_input(vote_input),

    .BJP_votes(BJP_votes),
    .INC_votes(INC_votes),
    .AAP_votes(AAP_votes),
    .SP_votes(SP_votes)
);
//////////////////////////////////////////////////////
// RESULT MODE
//////////////////////////////////////////////////////

result_mode RESULT(
    

    .admin_success(admin_success),

    .BJP_votes(BJP_votes),
    .INC_votes(INC_votes),
    .AAP_votes(AAP_votes),
    .SP_votes(SP_votes)
);

endmodule