module admin_auth(

    input clk,
    input reset,

    input [15:0] admin_password,
    input admin_valid,

    input admin_logout,

    output reg admin_success
);

parameter ADMIN_PASS = 16'd1234;

always @(posedge clk or posedge reset) begin

    if(reset) begin

        admin_success <= 0;
    end

    else begin

        //////////////////////////////////////////////////
        // LOGIN
        //////////////////////////////////////////////////

        if(admin_valid) begin

            if(admin_password == ADMIN_PASS) begin

                admin_success <= 1;

                $display(" ");
                $display("=================================");
                $display(" ADMIN LOGIN SUCCESSFUL ");
                $display("=================================");
            end

            else begin

                admin_success <= 0;

                $display(" ");
                $display("=================================");
                $display(" INVALID ADMIN PASSWORD ");
                $display("=================================");
            end
        end

        //////////////////////////////////////////////////
        // LOGOUT
        //////////////////////////////////////////////////

        if(admin_logout) begin

            admin_success <= 0;

            $display(" ");
            $display("=================================");
            $display(" ADMIN LOGOUT ");
            $display("=================================");
        end
    end
end

endmodule