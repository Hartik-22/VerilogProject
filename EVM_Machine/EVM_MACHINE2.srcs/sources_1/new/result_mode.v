module result_mode(

    input admin_success,

    input [15:0] BJP_votes,
    input [15:0] INC_votes,
    input [15:0] AAP_votes,
    input [15:0] SP_votes
);

always @(*) begin

    if(admin_success) begin

        $display(" ");
        $display("====================================");
        $display("         ELECTION RESULTS           ");
        $display("====================================");

        $display("BJP Votes = %d", BJP_votes);
        $display("INC Votes = %d", INC_votes);
        $display("AAP Votes = %d", AAP_votes);
        $display("SP Votes  = %d", SP_votes);

        $display("------------------------------------");

        //////////////////////////////////////////////////
        // WINNER DETECTION
        //////////////////////////////////////////////////

        if(BJP_votes > INC_votes &&
           BJP_votes > AAP_votes &&
           BJP_votes > SP_votes)

            $display("WINNER = BJP");

        else if(INC_votes > BJP_votes &&
                INC_votes > AAP_votes &&
                INC_votes > SP_votes)

            $display("WINNER = INC");

        else if(AAP_votes > BJP_votes &&
                AAP_votes > INC_votes &&
                AAP_votes > SP_votes)

            $display("WINNER = AAP");

        else if(SP_votes > BJP_votes &&
                SP_votes > INC_votes &&
                SP_votes > AAP_votes)

            $display("WINNER = SP");

        else
            $display("TIE DETECTED");

        $display("====================================");
    end
end

endmodule