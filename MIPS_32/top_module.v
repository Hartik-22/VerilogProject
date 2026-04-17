module top_module(clk1,clk2);
    input clk1,clk2;
    reg [31:0] PC,IF_ID_IR, IF_ID_NPC;
    reg [31:0] ID_EX_NPC, ID_EX_IR, ID_EX_A, ID_EX_B, ID_EX_Imm;
    reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
    reg [31:0] EX_MEM_IR, EX_MEM_ALUout, EX_MEM_B;
    reg EX_MEM_cond;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUout, MEM_WB_LMD;

    reg [31:0] Reg[0:31];
    reg [31:0] Mem[0:1023];

    parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011, SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111, LW = 6'b001000, SW = 6'b001001, ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100, BNEQZ = 6'b001101, BEQZ = 6'b001110, NOP = 6'b011110;
    
    parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, BRANCH = 3'b100, HALT = 3'b101, NTYPE = 3'b110; 

    reg HALTED; //SET AFTER HLT INSTRUCTION IS COMPLETED, PREVENTS NEW INSTRUCTION FROM BEING FETCHED

    reg FLUSH; //USED TO FLUSH THE PIPELINE WHEN BRANCH IS TAKEN

    reg stall; //USED TO STALL THE PIPELINE, PREVENTS NEW INSTRUCTION FROM BEING FETCHED AND PREVENTS PC FROM BEING UPDATED
    reg [1:0] forwardA, forwardB; //00 = NO FORWARDING, 01 = FORWARD FROM EX-MEM STAGE, 10 = FORWARD FROM MEM-WB STAGE
    reg [31:0] ALU_A, ALU_B; //INPUTS TO THE ALU, DETERMINED BY FORWARDING LOGIC
    reg [4:0] EX_MEM_dest, MEM_WB_dest; //DESTINATION REGISTER NUMBERS FOR EX-MEM AND MEM-WB STAGES, USED IN FORWARDING LOGIC

    reg BHT [0:15]; //SIMPLE 1-BIT BRANCH HISTORY TABLE WITH 16 ENTRIES, INDEXED BY LOWER 4 BITS OF THE BRANCH INSTRUCTION ADDRESS

    reg IF_ID_pred; // prediction made in IF stage
    reg ID_EX_pred; // prediction passed to EX stage
    reg actual_taken;
    reg [31:0] BTB [0:15];//stores target value of branch , indexed by lower 4 bits of branch instruction address
    reg BTB_valid [0:15]; 
    reg [31:0] ID_EX_PC; 
    reg [31:0] next_PC;
    reg PC_write;


    //--------------------------------------- IF STAGE ---------------------------------------
    always @(posedge clk1)
        begin
            if (HALTED) begin
                IF_ID_IR <=  NOP; //IF HALTED, INSERT NOP IN IF/ID REGISTER TO PREVENT FURTHER INSTRUCTION FROM BEING PROCESSED
                IF_ID_NPC <= 0;
                // PC <= PC; //HOLD THE PC CONSTANT
            end
            else
                begin 

                if(PC_write) begin
                    PC <= next_PC;
                    PC_write <= 0; //RESET PC_WRITE SIGNAL
                end

                if (FLUSH)
                begin
                    IF_ID_IR <= NOP;
                    IF_ID_NPC <= 0;
                end

            else if(stall)
            begin
                //HOLD THE PC AND IF/ID REGISTERS CONSTANT FOR ONE CYCLE TO STALL THE PIPELINE
                IF_ID_IR <=  IF_ID_IR;
                IF_ID_NPC <=  IF_ID_NPC;
                // PC <=  PC;    
            end

            else 
                begin
                    // TAKEN_BRANCH <= 0;
                    // IF_ID_IR <=  Mem[PC];
                    // IF_ID_NPC <=  PC + 1;
                    // PC <=  PC + 1;
                    //BRANCH PREDICTION LOGIC
                    IF_ID_pred <= BHT[PC[3:0]];
                    // TAKEN_BRANCH <= 0;
                    IF_ID_IR <= Mem[PC]; //FETCH THE INSTRUCTION
                    IF_ID_NPC <= PC + 1; //CALCULATE THE NEXT PC

                    // if(PC_write) begin
                    //     PC <= next_PC;
                    //     PC_write <= 0; //RESET PC_WRITE SIGNAL
                    // end

                    if(BHT[PC[3:0]] == 1'b1 && BTB_valid[PC[3:0]] == 1'b1) //PREDICT TAKEN
                    begin
                        PC <=  BTB[PC[3:0]]; //UPDATE THE PC
                    end
                    else //PREDICT NOT TAKEN
                    begin
                        PC <=  PC + 1; //UPDATE THE PC
                    end

                   
                end
            end
        end

    //--------------------------------------- ID STAGE ---------------------------------------

    always @(*) //CHECK FOR LOAD-USE HAZARD
        begin
            stall = 0;

            if (ID_EX_type == LOAD && (ID_EX_IR[20:16] != 0) &&
                ((ID_EX_IR[20:16] == IF_ID_IR[25:21]) || 
                (ID_EX_IR[20:16] == IF_ID_IR[20:16])))
                begin
                    stall = 1;
                end
        end

    always @(posedge clk2)
        begin

            if(FLUSH || HALTED)
                begin
                    //IF A BRANCH WAS TAKEN, FLUSH THE INSTRUCTION IN THE ID/EX REGISTER TO PREVENT IT FROM BEING PROCESSED
                    ID_EX_IR   <=  NOP;
                    ID_EX_type <=  NTYPE;
                    ID_EX_A    <=  0;
                    ID_EX_B    <=  0;
                    ID_EX_Imm  <=  0;
                    ID_EX_NPC  <=  0;
                end

            else if (stall) 
                begin
                // INSERT NOP
                    ID_EX_IR   <=  NOP;
                    ID_EX_type <=  NTYPE;
                    ID_EX_A    <=  0;
                    ID_EX_B    <=  0;
                    ID_EX_Imm  <=  0;
                ID_EX_NPC  <=  0;
                end
            else 
                begin
                if(IF_ID_IR[25:21] == 5'b00000)  ID_EX_A <= 0;
                else ID_EX_A <=  Reg[IF_ID_IR[25:21]];
        
                if(IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;
                else ID_EX_B <=  Reg[IF_ID_IR[20:16]];
            
                ID_EX_NPC <=  IF_ID_NPC;
                ID_EX_PC <= IF_ID_NPC -1;
                ID_EX_IR <=  IF_ID_IR;
                ID_EX_Imm <=  {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};
                ID_EX_pred <= IF_ID_pred;

                  case (IF_ID_IR[31:26])
                      ADD, SUB, AND, OR, SLT, MUL: ID_EX_type <=  RR_ALU;
                                ADDI, SUBI, SLTI: ID_EX_type <=  RM_ALU;
                                LW: ID_EX_type <=  LOAD;
                                SW: ID_EX_type <=  STORE;
                                BEQZ, BNEQZ: ID_EX_type <=  BRANCH;
                                HLT: ID_EX_type <=  HALT;
                                NOP: ID_EX_type <=  NTYPE; // NO-OPERATION INSTRUCTION, DOES NOTHING
                                default: ID_EX_type <=  HALT; //UNRECOGNIZED INSTRUCTION, HALT THE MACHINE
                            endcase
                        end          
        end

    

    //------------------------------------------- EX STAGE -------------------------------------------
    
    always @(*) //FORWARDING UNIT LOGIC
        begin
            //Default values for forwarding
            forwardA = 2'b00;
            forwardB = 2'b00;

            if((EX_MEM_type == RR_ALU || EX_MEM_type == RM_ALU) && (EX_MEM_dest != 0) ) 
                begin
                    if  (EX_MEM_dest == ID_EX_IR[25:21])
                    forwardA = 2'b10; //FORWARD FROM EX-MEM

                    if(EX_MEM_dest == ID_EX_IR[20:16])
                    forwardB = 2'b10; //FORWARD FROM EX-MEM
                end

            if ((MEM_WB_type != NTYPE && MEM_WB_type != STORE ) && (MEM_WB_dest != 0))     begin                
                if ( !( (EX_MEM_type == RR_ALU || EX_MEM_type == RM_ALU) &&(EX_MEM_dest != 0) &&(EX_MEM_dest == ID_EX_IR[25:21])) && (MEM_WB_dest == ID_EX_IR[25:21]))
                forwardA = 2'b01; //FORWARD FROM MEM-WB

                if( !( (EX_MEM_type == RR_ALU || EX_MEM_type == RM_ALU) &&(EX_MEM_dest != 0)  &&(EX_MEM_dest == ID_EX_IR[20:16])) && (MEM_WB_dest == ID_EX_IR[20:16]))
                forwardB = 2'b01; //FORWARD FROM MEM-WB
            end

        end
    
    always @(*)
        begin
     
            case (forwardA)
                2'b00: ALU_A = ID_EX_A; //NO FORWARDING
                2'b01: ALU_A = (MEM_WB_type == LOAD)?MEM_WB_LMD:MEM_WB_ALUout; //FORWARD FROM MEM-WB
                2'b10: ALU_A = EX_MEM_ALUout; //FORWARD FROM EX-MEM
                default : ALU_A = ID_EX_A;
            endcase

            case (forwardB)
                2'b00: ALU_B = ID_EX_B; //NO FORWARDING
                2'b01: ALU_B = (MEM_WB_type == LOAD)?MEM_WB_LMD:MEM_WB_ALUout; //FORWARD FROM MEM-WB
                2'b10: ALU_B = EX_MEM_ALUout; //FORWARD FROM EX-MEM
                default : ALU_B = ID_EX_B;
            endcase
        end

    always @(posedge clk1) 
    begin
         
       FLUSH <= 0;
        actual_taken = 0; 
        EX_MEM_IR   <=  ID_EX_IR;
        EX_MEM_type <=  ID_EX_type;
        // TAKEN_BRANCH <=  0;

        //  destination tracking
        if (ID_EX_type == RR_ALU)
                EX_MEM_dest <=  ID_EX_IR[15:11];
        else
            EX_MEM_dest <=  ID_EX_IR[20:16];

        //ALU OPERATIONS
        case (ID_EX_type)
                    RR_ALU : begin
                        case (ID_EX_IR[31:26])
                            ADD: EX_MEM_ALUout <=  ALU_A + ALU_B;
                            SUB: EX_MEM_ALUout <=  ALU_A - ALU_B;
                            AND: EX_MEM_ALUout <=  ALU_A & ALU_B;
                            OR: EX_MEM_ALUout <=  ALU_A | ALU_B;
                            SLT: EX_MEM_ALUout <=  (ALU_A < ALU_B) ? 32'h1 : 32'h0;
                            MUL: EX_MEM_ALUout <=  ALU_A * ALU_B;
                            default: EX_MEM_ALUout <=  32'hXXXXXXXX; //UNRECOGNIZED INSTRUCTION, RESULT UNDEFINED
                        endcase
                    end

                    RM_ALU : begin
                        case (ID_EX_IR[31:26])
                            ADDI : EX_MEM_ALUout <=  ALU_A + ID_EX_Imm;
                            SUBI : EX_MEM_ALUout <=  ALU_A - ID_EX_Imm;
                            SLTI : EX_MEM_ALUout <=  (ALU_A < ID_EX_Imm ) ? 32'h1 : 32'h0; 
                            default: EX_MEM_ALUout <=  32'hXXXXXXXX; //UNRECOGNIZED INSTRUCTION, RESULT UNDEFINED
                        endcase
                    end

                    LOAD, STORE: begin
                        EX_MEM_ALUout <=  ALU_A + ID_EX_Imm; //CALCULATE EFFECTIVE ADDRESS
                        EX_MEM_B <=  ALU_B; //VALUE TO BE STORED IN MEMORY
                    end

                    BRANCH: begin
                        EX_MEM_ALUout <=  ID_EX_PC + ID_EX_Imm; //CALCULATE BRANCH TARGET ADDRESS
                        EX_MEM_cond <=  (ALU_A == 0) ? 1'b1 : 1'b0; //CHECK IF BRANCH CONDITION IS MET
                        
                        actual_taken = (ID_EX_IR[31:26] == BEQZ && ALU_A == 0) || (ID_EX_IR[31:26] == BNEQZ && ALU_A != 0) ;
                        BHT[ID_EX_PC[3:0]] <= actual_taken; //UPDATE BHT WITH THE ACTUAL OUTCOME OF THE BRANCH
                        if(actual_taken) begin
                            BTB[ID_EX_PC[3:0]] <= ID_EX_PC + ID_EX_Imm ;
                            BTB_valid[ID_EX_PC[3:0]] <= 1'b1;

                        end

                        FLUSH <= (ID_EX_pred != actual_taken);

                        if(ID_EX_pred != actual_taken) //MISPREDICTION
                        begin
                           
                            PC_write <= 1'b1;
                            if(actual_taken) //ACTUALLY TAKEN
                                next_PC <= ID_EX_PC + ID_EX_Imm;//UPDATE PC TO THE CORRECT TARGET ADDRESS
                            else
                                next_PC <= ID_EX_NPC; //UPDATE PC TO THE CORRECT NEXT SEQUENTIAL ADDRESS
                        end

                    end

                    HALT: begin
                        HALTED <=  1'b1;
                        FLUSH <= 1'b1; //FLUSH THE PIPELINE TO PREVENT ANY FURTHER INSTRUCTIONS FROM BEING PROCESSED
                        EX_MEM_ALUout <=  32'hXXXXXXXX; //RESULT UNDEFINED
                    end

                    NTYPE: begin
                        EX_MEM_ALUout <=  32'hXXXXXXXX; //NO-OPERATION INSTRUCTION, RESULT UNDEFINED
                    end

                    default: EX_MEM_ALUout <=  32'hXXXXXXXX; //UNRECOGNIZED INSTRUCTION, RESULT UNDEFINED
                endcase

            

        end

    //----------------------------------------------- MEM STAGE -----------------------------------------------
    always @(posedge clk2)
        begin
            MEM_WB_IR   <=  EX_MEM_IR;
            MEM_WB_type <=  EX_MEM_type;

            //  Correct propagation
            MEM_WB_dest <=  EX_MEM_dest;

                    case (EX_MEM_type)
                        RR_ALU, RM_ALU: MEM_WB_ALUout <=  EX_MEM_ALUout;
                        LOAD: MEM_WB_LMD <=  Mem[EX_MEM_ALUout]; //READ FROM MEMORY
                        STORE: Mem[EX_MEM_ALUout] <=  EX_MEM_B; //
                        NTYPE: MEM_WB_ALUout <=  32'hXXXXXXXX; //NO-OPERATION INSTRUCTION, RESULT UNDEFINED
                        default: MEM_WB_ALUout <=  32'hXXXXXXXX; //UNRECOGNIZED INSTRUCTION, RESULT UNDEFINED
                    endcase
                end
        //end

    //--------------------------------------------- WB STAGE ---------------------------------------------
    always @(posedge clk1)
        begin
                    if(!HALTED) begin
                    case (MEM_WB_type)
                        RR_ALU: Reg[MEM_WB_IR[15:11]] <=  MEM_WB_ALUout; //R-TYPE INSTRUCTION, WRITE TO RD
                        RM_ALU: Reg[MEM_WB_IR[20:16]] <=  MEM_WB_ALUout; //I-TYPE INSTRUCTION, WRITE TO RT
                        LOAD: Reg[MEM_WB_IR[20:16]] <=  MEM_WB_LMD; //LOAD INSTRUCTION, WRITE LOADED VALUE TO RT
                        // HALT: HALTED <=  1'b1; //SET HALTED FLAG, PREVENTS NEW INSTRUCTION FROM BEING FETCHED
                        NTYPE: ; //NO-OPERATION INSTRUCTION, DOES NOTHING
                        default: ; //STORE AND BRANCH INSTRUCTIONS DO NOT WRITE BACK TO REGISTER FILE
                    endcase
                end
            end
endmodule