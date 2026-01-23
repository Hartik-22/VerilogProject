`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/23/2026 11:20:05 AM
// Design Name: 
// Module Name: fir_filter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fir_filter( input_data, clk, rst, enable,output_data, sampleT
    );
    parameter N1 = 8, N2 = 16, N3 = 32;
    input signed [N2-1:0]input_data;
    input clk,rst,enable;
    output signed [N3-1:0] output_data;
    output signed [N2-1:0] sampleT;
    wire signed [N1-1:0] b[0:7];
    assign b[0] = 8'b00010000;
    assign b[1] = 8'b00010000;
    assign b[2] = 8'b00010000;
    assign b[3] = 8'b00010000;
    assign b[4] = 8'b00010000;
    assign b[5] = 8'b00010000;
    assign b[6] = 8'b00010000;
    assign b[7] = 8'b00010000;
    
    reg signed [N3-1:0] output_data_reg;
    reg signed [N2-1:0] past_input_samples [0:6];
    
    always @(posedge clk)
        begin
            if(rst == 1'b1)
                begin
                    past_input_samples[0] <= 0;
                    past_input_samples[1] <= 0;
                    past_input_samples[2] <= 0;
                    past_input_samples[3] <= 0;
                    past_input_samples[4] <= 0;
                    past_input_samples[5] <= 0;
                    past_input_samples[6] <= 0;
                    output_data_reg <= 0;
                end
                
             else if ((enable==1'b1) && (rst == 1'b0))
                begin
                    output_data_reg <= (b[0] * input_data 
                                      + b[1] * past_input_samples[0]
                                      + b[2] * past_input_samples[1]
                                      + b[3] * past_input_samples[2]
                                      + b[4] * past_input_samples[3]
                                      + b[5] * past_input_samples[4]
                                      + b[6] * past_input_samples[5]
                                      + b[7] * past_input_samples[6])>>>(N1-1);
                     past_input_samples[0] <= input_data;
                     past_input_samples[1] <= past_input_samples[0];
                     past_input_samples[2] <= past_input_samples[1];
                     past_input_samples[3] <= past_input_samples[2];  
                     past_input_samples[4] <= past_input_samples[3];
                     past_input_samples[5] <= past_input_samples[4];
                     past_input_samples[6] <= past_input_samples[5];
                end
        end
    
    assign output_data = output_data_reg;
    assign sampleT = past_input_samples[0];
endmodule
