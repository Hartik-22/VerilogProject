module invalid_counter(

    input clk,
    input reset,

    input auth_fail,

    output reg [15:0] invalid_attempts
);

always @(posedge clk or posedge reset) begin

    if(reset)
        invalid_attempts <= 0;

    else if(auth_fail)
        invalid_attempts <= invalid_attempts + 1;
end

endmodule