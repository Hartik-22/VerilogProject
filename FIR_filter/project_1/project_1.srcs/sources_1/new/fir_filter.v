`timescale 1ns / 1ps
/*
    Project: Pipelined Fixed-Point FIR Filter
    Author : Hartik Rai
    Date : 29th Jan 2025
    Updated : 2nd Feb 2025
    File : fir_filter.v
    Features :
        - Parameterized FIR filter (TAPS, input/output bit widths)
        - Fixed-point signed arithmetic (Q-format coefficients)
        - Fully pipelined architecture for high-throughput operation
        - Parallel multipliers with adder-tree based accumulation
        - Supports even and odd number of taps
        - Saturation arithmetic to prevent overflow
        - One output per clock cycle after pipeline fill
        - External coefficient loading via file
        - Verified against Python golden reference model
        - Quantization error and SNR analysis performed

*/
module fir_filter( input_data, clk, rst, enable,output_data, sampleT);
    // N1 = filter coefficient width , N2 = input samples width, N3 = output samples width
    parameter TAPS = 8, N1 = 8, N2 = 16, N3 = 32; 
    input signed [N2-1:0]input_data; //input is 16 bit
    input clk,rst,enable;
    output reg signed [N3-1:0] output_data; //output is 32 bit
    output signed [N2-1:0] sampleT; //help in debugging
    //filter-coefficients
    reg signed [N1-1:0] coeff[0:TAPS-1]; //eight 8-bit filter coefficient
    initial $readmemb("C:/Users/Hartik Rai/OneDrive/Dokumen/projects/FIR_filter/coeff.data.txt",coeff); //reading coeff from file
    localparam signed [N3-1:0] MAX_VAL = (1 <<< (N3-1)) - 1; //maximum positive value for N3 bits
    localparam signed [N3-1:0] MIN_VAL = -(1 <<< (N3-1)); //minimum value for N3 bits
    localparam integer PARTIALS = (TAPS+1)/2; //number of partial sums after first stage of accumulation
    reg signed [N3-1:0] acc_comb,acc_next; 
    reg signed [N3-1:0] scaled_comb,scaled_next;
    reg signed [N3-1:0] sat_comb;
    reg signed [N2-1:0] past_input_samples [0:TAPS-2]; //delay line for past input samples
    integer i;
    reg signed [N3-1:0] mult_reg[0:TAPS-1]; //to store multiplication results in stage 1
    reg signed [N3-1:0] partial_acc [0:PARTIALS-1]; //to store partial sums in stage 2
    reg signed [N3-1:0] final_acc; //to store final accumulation result in stage 3
    reg signed [N3-1:0] final_acc_temp; //to hold combinational final accumulation result
    //Pipeline implementation
    
    //Stage 0 (Input delay line)
    //load the past input samples into shift register
    always @(posedge clk)
        begin
            if(rst)
                begin
                    for( i = 0;i<TAPS-1;i=i+1)
                        past_input_samples[i] <= 0;
                end
           else if(enable) 
            begin
                for(i = TAPS-2;i>0;i=i-1)
                    past_input_samples[i] <= past_input_samples[i-1];
                
                past_input_samples[0] <= input_data;
            end               
        end
    
    //Stage 1 (Multiplication of current input with all coefficient)
    always @(posedge clk)
        begin
            if(rst) 
                begin 
                    for(i = 0;i <TAPS;i=i+1)
                        mult_reg[i] <= 0;
                end
            else if(enable)
                begin
                    mult_reg[0] <= input_data * coeff[0];
                    for(i = 1;i<TAPS;i = i+1)
                        mult_reg[i] <= past_input_samples[i-1] * coeff[i];
                end
        end
    
    //Stage 2 (Partial Accumulation)
    //Pairwise addition 
    
    always @(posedge clk)
        begin
            if(rst) 
                begin
                    for (i =0;i<PARTIALS;i=i+1)
                        partial_acc[i] <= 0;
                end
            else if(enable)
                begin
                    for(i =0;i<PARTIALS;i=i+1)
                        begin
                        if((2*i+1)<TAPS) 
                            partial_acc[i] <=  mult_reg[2*i] + mult_reg[2*i+1];
                        else 
                            partial_acc[i] <= mult_reg[2*i];//leftover taps
                        end
                end
        end
        
    //Stage 3 (Final accumulation)
    //Combinational part to sum up partial_acc[]
    always @(*)
        begin
            final_acc_temp = 0;
            for(i =0;i<PARTIALS;i = i+1)
                final_acc_temp = final_acc_temp + partial_acc[i];
        end
    //Sequential part to register the final accumulation result
    always @(posedge clk)
        begin
            if(rst) final_acc <= 0;
            else if(enable) 
                final_acc <= final_acc_temp;
        end
    
    
    //Stage 4 (Scaling & Saturation)

    
    always @(posedge clk)
        begin
           if(rst) 
                output_data <= 0;
           else if(enable)
            begin
                scaled_comb <= final_acc >>> (N1-1);
                if ((final_acc >>> (N1-1)) > MAX_VAL)
                    output_data <= MAX_VAL;
                else if ((final_acc >>> (N1-1)) < MIN_VAL)
                    output_data <= MIN_VAL;
                else
                    output_data <= (final_acc >>> (N1-1));
            end
            
        end
    
    //without pipelining
    //Combinational Part
//    always @(*)
//        begin
//            acc_comb    = 0;
//            scaled_comb = 0;
//            sat_comb    = 0;
//            acc_comb = coeff[0] * input_data; //h[0]*x[n]
//            for(i =1;i<TAPS;i = i +1)
//                acc_comb = acc_comb + coeff[i]*past_input_samples[i-1];
//            //scaling 
//            scaled_comb = acc_comb >>> (N1-1); 
            
//            //Saturation logic
//            if(scaled_comb > MAX_VAL)
//                sat_comb = MAX_VAL;
//            else if (scaled_comb < MIN_VAL)
//                sat_comb = MIN_VAL;
//            else sat_comb = scaled_comb;
//        end
    
    
    //Sequential part
//    always @(posedge clk)
//        begin
//            if(rst == 1'b1) begin
//                output_data <= 0;
//                for(i = 0;i<TAPS-1;i= i+1)
//                    past_input_samples[i] <= 0;
//            end
            
//            else if ((enable == 1'b1)&&(rst == 1'b0)) begin
//                output_data <= sat_comb;
//                for(i =TAPS-2;i>0;i=i-1)
//                    past_input_samples[i] <= past_input_samples[i-1];
//                 past_input_samples[0] <= input_data;
//            end
//        end

    assign sampleT = past_input_samples[0]; // 1-cycle delayed input
    
endmodule
