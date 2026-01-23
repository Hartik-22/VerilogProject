`timescale 1ns / 1ps

module testbench;
    parameter N1 = 8, N2 = 16, N3 = 32;
    reg signed [N2-1:0] input_data;
    reg clk;
    reg rst;
    reg enable;
    wire signed [N3-1:0] output_data;
    wire signed  [N2-1:0] sampleT;
    reg signed [N2-1:0] data[99:0];
    fir_filter UUT(
    .input_data(input_data),
     .clk(clk), 
     .rst(rst),
     .enable(enable),
     .output_data(output_data), 
     .sampleT(sampleT)
     );
     
     integer k;
     integer FILE1;
     
  
     initial
        begin
            k = 0;
            clk = 1'b0;
            enable = 1'b0;
            input_data = 0;
            
            $readmemb("C:/Users/Hartik Rai/OneDrive/Dokumen/projects/FIR_filter/input.data.txt",data);
            FILE1 = $fopen("save.data","w");
            $display("RAW FILE CHECK:");
            $display("data[0] = %b", data[0]);
            $display("data[1] = %b", data[1]);
            $display("data[2] = %b", data[2]);

            #20 rst = 1'b1;
            #40 rst = 1'b0;
            
            @(posedge clk);
            enable = 1;
            input_data = data[0];            
            
            #10
            for(k = 1;k<100;k=k+1)
                begin
                    @(posedge clk);
                    
                    input_data <= data[k];
                    if(k >= 7) 
                        $fdisplay(FILE1,"%b",output_data); 
                end
            $fclose(FILE1);
           
        end
        
       always #10 clk = ~clk;
     
endmodule
