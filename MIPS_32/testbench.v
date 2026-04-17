/*
Testbench for MIPS 32-bit processor
This testbench will simulate a simple program that performs basic arithmetic operations and memory access. The program will be loaded into the instruction memory, and the testbench will monitor the outputs of the processor to verify correct functionality.
The starting addres of the memory is 0x00000000, and thee value of pc is initialized to 0x00000000. 
Example Program 2:
     Initial value at memory address 120 IS 85
    ADDI R1,R0,120 ; R1 = 120 ; 001010 00000 00001 0000000001111000
    LW R2,0(R1) ; R2 = Mem[R1] = 85 ; 001000 00001 00010 0000000000000000
    ADDI R2, R2, 45 ; R2 = R2 + 45 = 130  ; 001010 00010 00010 0000000000101101
    SW R2, 1(R1) ; Mem[R1+1] = R2 ; 001001 00010 00001 0000000000000001
    HLT ; HALT the processor ; 111111 00000 00000 00000 00000 000000
The testbench will monitor the values of the registers and the memory to ensure that the instructions are executed correctly. 


*/

`timescale 1ns/1ps
`include "top_module.v"

module test_mips32;
    reg clk1, clk2;
    integer k;
    top_module UUT(clk1, clk2);

    initial begin
        // Initialize clock signals
        clk1 = 0; clk2 = 0;
        repeat(50) begin
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;
            
        end
    end
    

    integer i;
    initial begin
    UUT.PC = 0;
    UUT.HALTED = 0;
    UUT.FLUSH = 0;

    UUT.IF_ID_IR = 0;
    UUT.IF_ID_NPC = 0;

    UUT.ID_EX_IR = 0;
    UUT.ID_EX_A = 0;
    UUT.ID_EX_B = 0;
    UUT.ID_EX_NPC = 0;
    UUT.ID_EX_Imm = 0;
    UUT.ID_EX_type = 0;

    UUT.EX_MEM_IR = 0;
    UUT.EX_MEM_ALUout = 0;
    UUT.EX_MEM_B = 0;
    UUT.EX_MEM_type = 0;

    UUT.MEM_WB_IR = 0;
    UUT.MEM_WB_ALUout = 0;
    UUT.MEM_WB_LMD = 0;
    UUT.MEM_WB_type = 0;
    for(i = 0; i < 16; i = i + 1) begin UUT.BHT[i] = 0; // default not taken
        UUT.BTB[i] = 0;
        UUT.BTB_valid[i] = 0;
    end
end

    initial begin
            // $monitor("Time=%0t | WB_type=%d | R1=%d", $time, UUT.MEM_WB_type, UUT.Reg[1]);
        for(k =0;k<32;k = k+1) UUT.Reg[k] = k; //INITIALIZE REGISTERS TO THEIR INDEX VALUE FOR EASY DEBUGGING
 
        // Load the test program into memory
        //program 1 (to check basic functionality)
        // UUT.Mem[0] = 32'h2801000a; // ADDI R1, R0, 10
        // UUT.Mem[1] = 32'h28020014; // ADDI R2, R0, 20
        // UUT.Mem[2] = 32'h28030019; // ADDI R3, R0, 25
        // UUT.Mem[3] = 32'h00222000; // ADD R4, R1, R2
        // UUT.Mem[4] = 32'h00832800; // ADD R5, R4, R3
        // UUT.Mem[5] = 32'hfc000000; // HLT
        
        //program 2 (to check stalling and memory access)
        // UUT.Mem[0] = 32'h28010078; // ADDI R1, R0, 120  
        // UUT.Mem[1] = 32'h20220000; // LW R2, 0(R1)  
        // UUT.Mem[2] = 32'h2842002d; // ADDI R2, R2, 45
        // UUT.Mem[3] = 32'h24220001; // SW R2, 1(R1)
        // UUT.Mem[4] = 32'hfc000000; // HLT
        
        //program 3 (to check forwarding)
        // UUT.Reg[1] = 120; // Load the base address into R1
        // UUT.Mem[0] = 32'h00430800; // 
        // UUT.Mem[1] = 32'h00221800;
        // //UUT.Mem[2] = 32'h78000000; // 
        // UUT.Mem[2] = 32'hfc000000; // HLT
        
        //program 4 (to check chain forwarding)
            // UUT.Mem[0] = 32'h28020002; // ADDI R2, R0, 2
            // UUT.Mem[1] = 32'h28030003; // ADDI R3, R0, 3
            // UUT.Mem[2] = 32'h00430800 ; // ADD R1, R2, R3
            // UUT.Mem[3] = 32'h00222000; // ADD R4, R1, R2
            // UUT.Mem[4] = 32'h00832800; // ADD R5, R3, R4
            // UUT.Mem[5] = 32'hfc000000; // HLT

        //program 5 (MEM_WB forwarding check)
        // UUT.Mem[0] = 32'h28020002; // ADDI R2, R0, 2
        // UUT.Mem[1] = 32'h28030003; // ADDI R3, R0, 3
        // UUT.Mem[2] = 32'h00430800 ; // ADD R1, R2, R3
        // UUT.Mem[3] = 32'h78000000; // NOP (NO-OPERATION INSTRUCTION)
        // UUT.Mem[4] = 32'h00222000; // ADD R4, R1, R2
        // UUT.Mem[5] = 32'hfc000000; // HLT


        //PROGRAM 6 (LOAD -> STORE DEPENDENCY CHECK)
        // UUT.Mem[0] = 32'h28010078; // ADDI R1, R0, 120  
        // UUT.Mem[1] = 32'h20220000; // LW R2, 0(R1)
        // UUT.Mem[3] = 32'h24220001; // SW R2, 1(R1)  

        //PROGRAM 7 (ALUOP -> STORE DEPENDENCY CHECK)
        // UUT.Mem[0] = 32'h28020002; // ADDI R2, R0, 2
        // UUT.Mem[1] = 32'h28030003; // ADDI R3, R0, 3
        // UUT.Mem[2] = 32'h00430800 ; // ADD R1, R2, R3
        // UUT.Mem[3] = 32'h24210000; // SW R1, 0(R1)
        // UUT.Mem[4] = 32'hfc000000; // HLT

        //PROGRAM 8 (PRIORITY TEST CHECK)
        // UUT.Mem[0] = 32'h28020002; // ADDI R2, R0, 2
        // UUT.Mem[1] = 32'h28030003; // ADDI R3, R0, 3
        // UUT.Mem[2] = 32'h00430800 ; // ADD R1, R2, R3
        // UUT.Mem[3] = 32'h00220800; 
        // UUT.Mem[4] = 32'h00232000;
        // UUT.Mem[5] = 32'hfc000000; // HLT

        //PROGRAM 9 (BRANCH INSTRUCTION CHECK)
        UUT.Mem[0] = 32'h28010000; // ADDI R1, R0, 0
        UUT.Mem[1] = 32'h38200004; // BEQZ R1, 4 (BRANCH TO PC+4=6 IF R1 == 0)
        UUT.Mem[2] = 32'h00430800 ; // ADD R1, R2, R3
        UUT.Mem[3] = 32'h00420800 ; // ADD R1, R2, R2
        UUT.Mem[5] = 32'h28030005; // ADDI R3, R0, 8
        UUT.Mem[6] = 32'h00421000 ;
        UUT.Mem[7] = 32'hfc000000;
        UUT.Mem[8] = 32'h28030007;
        UUT.Mem[9] = 32'hfc000000; // HLT
        UUT.Mem[120] = 85; // Initial value at memory address 120
        // Wait for the processor to execute the instructions
        UUT.HALTED = 0;
        // UUT.FLUSH = 0;
        UUT.PC = 0;

        #500;

        // Check the results
        $display("R1 = %d ", UUT.Reg[1]);
        $display("R2 = %d ", UUT.Reg[2]);
        $display("R3 = %d ", UUT.Reg[3]);
        $display("R4 = %d ", UUT.Reg[4]);
        $display("R5 = %d ", UUT.Reg[5]);
        $display("R6 = %d ", UUT.Reg[6]);
        $display("Mem[121] = %d ", UUT.Mem[121]);
        $display("Mem[5] = %d ", UUT.Mem[5]);
      
    end

    initial 
        begin
            $dumpfile("mips.vcd");
            $dumpvars(0, test_mips32);
            #600 $finish;
        end

endmodule
