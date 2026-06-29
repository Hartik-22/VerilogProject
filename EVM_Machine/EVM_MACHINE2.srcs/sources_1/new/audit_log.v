module audit_log(
    input vote_enable,
    input [15:0] voter_id,
    input [1:0] candidate
);

always @(*) begin

    if(vote_enable) begin

        case(candidate)

            2'b00:
            $display("AUDIT: Voter %d voted BJP at time %t",
                     voter_id,$time);

            2'b01:
            $display("AUDIT: Voter %d voted INC at time %t",
                     voter_id,$time);

            2'b10:
            $display("AUDIT: Voter %d voted AAP at time %t",
                     voter_id,$time);

            2'b11:
            $display("AUDIT: Voter %d voted SP at time %t",
                     voter_id,$time);
        endcase
    end
end

endmodule