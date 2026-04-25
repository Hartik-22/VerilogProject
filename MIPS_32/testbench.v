/*
Testbench for MIPS 32-bit processor
This testbench will simulate a simple program that performs basic arithmetic operations and memory access. The program will be loaded into the instruction memory, and the testbench will monitor the outputs of the processor to verify correct functionality.
The starting addres of the memory is 0x00000000, and thee value of pc is initialized to 0x00000000. 
The testbench will monitor the values of the registers and the memory to ensure that the instructions are executed correctly. 
*/

`timescale 1ns/1ps
`include "top_module.v"

module test_mips32;
    reg clk1, clk2;
    integer k;
    real CPI; // To calculate Cycles Per Instruction
    top_module UUT(clk1, clk2); // Instantiate the MIPS processor

    initial begin
        // Initialize clock signals
        clk1 = 0; clk2 = 0;
        repeat(100) begin
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end
    

    integer i;
    initial 
        begin
            //initialize all registers and pipeline registers to 0 at the start of the simulation
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
            UUT.cycle_count = 0;
            UUT.instr_count = 0;
            UUT.stall_count = 0;
            UUT.branch_count = 0;
            UUT.mispred_count = 0;
            for(i = 0; i < 16; i = i + 1) begin 
                UUT.BHT[i] = 2'b01; // default weak not taken (allow learning quickly)
                UUT.BTB[i] = 0;
                UUT.BTB_valid[i] = 0;
            end
        end

    initial 
        begin
           
            for(k =0;k<32;k = k+1) UUT.Reg[k] = k; //INITIALIZE REGISTERS TO THEIR INDEX VALUE FOR EASY DEBUGGING
 
            // Load the test program into memory
            //program 1 (to check basic functionality)
            UUT.Mem[0] = 32'h2801000a; // ADDI R1, R0, 10
            UUT.Mem[1] = 32'h28020014; // ADDI R2, R0, 20
            UUT.Mem[2] = 32'h28030019; // ADDI R3, R0, 25
            UUT.Mem[3] = 32'h00222000; // ADD R4, R1, R2
            UUT.Mem[4] = 32'h00832800; // ADD R5, R4, R3now 
            UUT.Mem[5] = 32'hfc000000; // HLT
            
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

            // //PROGRAM 9 (BRANCH INSTRUCTION and HALT CHECK)
            // UUT.Mem[0] = 32'h28010000; // ADDI R1, R0, 0
            // UUT.Mem[1] = 32'h38200004; // BEQZ R1, 4 (BRANCH TO PC+4=6 IF R1 == 0)
            // UUT.Mem[2] = 32'h00430800 ; // ADD R1, R2, R3 //not executed
            // UUT.Mem[3] = 32'h00420800 ; // ADD R1, R2, R2 //not executed
            // UUT.Mem[5] = 32'h28030005; // ADDI R3, R0, 8 //not executed
            // UUT.Mem[6] = 32'h00421000 ; // ADD R2, R2, R0 // executed
            // UUT.Mem[7] = 32'hfc000000; // HLT
            // UUT.Mem[8] = 32'h28030007; // ADDI R3, R0, 7 //not executed
            // UUT.Mem[9] = 32'hfc000000; // HLT



            //Program 10(LOOP AND BRANCH CHECK)
            // UUT.Mem[0] = 32'h28010003 ; // ADDI R1, R0, 3
            // //LOOP: 
            // UUT.Mem[1] = 32'h2c210001; // SUBI R1, R1, 1
            // UUT.Mem[2] = 32'h3420ffff; // BNEZ R1, -1 (BRANCH TO LOOP IF R1 != 0)
            // UUT.Mem[3] = 32'h28050009; // ADDI R5, R0, 9
            // UUT.Mem[4] = 32'hfc000000; // HLT

            //Program 11 (DATA + CONTROL HAZARD CHECK)
            // UUT.Mem[0] = 32'h28010001;   // ADDI R1, R0, 1
            // UUT.Mem[1] = 32'h2c210001;   // SUBI R1, R1, 1 → R1 = 0
            // UUT.Mem[2] = 32'h38200002;   // BEQZ R1, +2
            // UUT.Mem[3] = 32'h00222000;   // ADD R4, R1, R2 // should NOT execute
            // UUT.Mem[4] = 32'h28050008;   // ADDI R5, R0, 8
            // UUT.Mem[5] = 32'hfc000000;   // HLT


            //program 12 (LOAD->BRANCH DEPENDENCY CHECK)
            // UUT.Mem[0] = 32'h28010010;   // ADDI R1, R0, 16
            // UUT.Mem[1] = 32'h20220000;   // LW R2, 0(R1)
            // UUT.Mem[2] = 32'h38420002;   // BEQZ R2, +2
            // UUT.Mem[3] = 32'h00222000;   // ADD R4, R1, R2 // should NOT execute if R2 == 0
            // UUT.Mem[4] = 32'h2805000A;   // ADDI R5, R0, 10
            // UUT.Mem[5] = 32'hfc000000;
            // UUT.Mem[16] = 0; // Initial value at memory address 16 (R2 will be loaded with this value)
            
            
            //program 13(BTB Validation Check)
            // UUT.Mem[0] = 32'h28010002;   // R1 = 2
            // UUT.Mem[1] = 32'h2c210001;   // LOOP: SUBI
            // UUT.Mem[2] = 32'h3420FFFF;   // BNEQZ R1, -1
            // UUT.Mem[3] = 32'h28010002;   // reset R1
            // UUT.Mem[4] = 32'h2c210001;   // LOOP again
            // UUT.Mem[5] = 32'h3420FFFF; 
            // UUT.Mem[6] = 32'hfc000000;
            
            //program 14 (LOOP Check)
            UUT.Mem[0] = 32'h28010014;   // ADDI R1, R0, 20
            UUT.Mem[1] = 32'h2c210001;   // LOOP: SUBI R1, R1, 1
            UUT.Mem[2] = 32'h3420FFFF;   // BNEQZ R1, -1  (jump back to Mem[1])
            UUT.Mem[3] = 32'h28050009;   // ADDI R5, R0, 9
            UUT.Mem[4] = 32'hfc000000;   // HLT


            //UUT.Mem[120] = 85; // Initial value at memory address 120
            // Wait for the processor to execute the instructions
            UUT.HALTED = 0;
            // UUT.FLUSH = 0;
            UUT.PC = 0;
        end

    initial 
        begin
            $dumpfile("mips.vcd");
            $dumpvars(0, test_mips32);
            wait(UUT.HALTED);
            #50;  // allow pipeline to drain completely
            CPI = UUT.cycle_count * 1.0 / UUT.instr_count;
            // Check the results
            $display("R1 = %d ", UUT.Reg[1]);
            $display("R2 = %d ", UUT.Reg[2]);
            $display("R3 = %d ", UUT.Reg[3]);
            $display("R4 = %d ", UUT.Reg[4]);
            $display("R5 = %d ", UUT.Reg[5]);
            $display("R6 = %d ", UUT.Reg[6]);
            $display("Total Cycles = %d", UUT.cycle_count);
            $display("Total Instructions = %d", UUT.instr_count);
            $display("Stalls = %d", UUT.stall_count);
            $display("Branches = %d", UUT.branch_count);
            $display("Mispredictions = %d", UUT.mispred_count);
            $display("CPI = %f", CPI);
            $finish;
        end
endmodule
