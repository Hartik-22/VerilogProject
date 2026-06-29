module led_controller(

    input clk,
    input reset,

    input vote_enable,
    input [1:0] candidate,

    output reg led1,
    output reg led2,
    output reg led3,
    output reg led4
);

always @(posedge clk or posedge reset) begin

    if(reset) begin

        led1 <= 0;
        led2 <= 0;
        led3 <= 0;
        led4 <= 0;
    end

    else if(vote_enable) begin

        case(candidate)

            2'b00: begin
                led1 <= 1;
                led2 <= 0;
                led3 <= 0;
                led4 <= 0;
            end

            2'b01: begin
                led1 <= 0;
                led2 <= 1;
                led3 <= 0;
                led4 <= 0;
            end

            2'b10: begin
                led1 <= 0;
                led2 <= 0;
                led3 <= 1;
                led4 <= 0;
            end

            2'b11: begin
                led1 <= 0;
                led2 <= 0;
                led3 <= 0;
                led4 <= 1;
            end
        endcase
    end

    else begin

        led1 <= 0;
        led2 <= 0;
        led3 <= 0;
        led4 <= 0;
    end
end

endmodule