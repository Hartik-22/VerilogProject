# 32-bit Pipelined MIPS Processor with Hazard Handling and Branch Prediction (Verilog)

## 1. Overview
This project implements a **32-bit MIPS pipelined processor** using Verilog HDL. The design follows a classic **5-stage pipeline architecture** and incorporates key techniques used in modern processors such as **data hazard resolution, control hazard handling, and branch prediction**.

The primary objective of this project is to understand how instructions are executed efficiently in a pipelined environment while maintaining correctness through hazard handling mechanisms.

The processor supports a subset of MIPS instructions including arithmetic operations, memory access, and control flow instructions, and demonstrates how performance can be improved using techniques like **forwarding, stalling, and speculative execution**.

This implementation also includes **performance counters** to evaluate metrics such as CPI (Cycles Per Instruction), stalls, and branch mispredictions.


## 2. Key Features
* 32-bit architecture
* 32 general-purpose registers (R0 to R31)
* R0 register always contain constant 0 **(cannot be modified)**
* Program Counter (PC) is 32-bit and points to next instruction
* No condition flags(unlike some other architectures)
* Assumes 32-bit memory addressing
* Two phase clock is used to avoid race condition.

## 3. Architecture 
The processor is designed using a 5-stage pipeline architecture, where each instruction is divided into five sequential stages:
#### A. Instruction Fetch(IF)
* Fetches instruction from instruction memory using the Program Counter (PC)
* Predicts branch direction using BHT (Branch History Table)
* Updates PC:
   - Sequential: PC + 1
   - Predicted branch target (if branch predicted taken)
#### B. Instruction Decode(ID)
* Decodes opcode and identifies instruction type
* Reads source registers from register file
* Performs hazard detection:
  - Detects load-use hazards
  - Triggers stall if required
* Passes operands to next stage

#### C. Execute(EX)
* Performs ALU operations (ADD, SUB, etc.)
* Computes branch condition:
  - BEQZ → check if register == 0
  - BNEQZ → check if register ≠ 0
* Calculates branch target address
* Updates branch predictor (BHT + BTB)
* Generates control signals:
  - FLUSH (if misprediction)
  - PC_write (correct PC update)

#### D. Memory access(MEM)
* Performs memory operations:
  - Load(LW)
  - Store(SW)
* Passes data to next stage

#### E. Write Back(WB)
* Writes result back to register file
* Only valid instructions update registers

## 4. Instruction Set 
#### i. R-Type Instructions
Used for register-to-register operations

| OPCODE(6 bit) | Rs (5 bit) | Rt (5 bit) | Rd (5 bit) | Unused (11 bit) |

* Rs -> Source register 1
* Rt -> Source register 2
* Rd -> Destination register
* Followings instructions are there
  - ADD,  SUB, AND, OR, SLT, MUL, HLT, NOP

#### ii. I-Type Instructions
Used for immediate and memory operations.

| OPCODE(6 bit) | Rs (5 bit) | Rt (5 bit) | Immediate (16 bit) |

* Rs -> Source register
* Rt -> Destination register
* Followings instructions are there
  - LW, SW, ADDI,  SUBI, SLTI

#### iii. Branch Instructions

| OPCODE(6 bit) | Rs (5 bit) | unused (5 bit) | Offset (16 bit) |

* Rs -> Source register
* Offset is signed
* Target address = PC + Offset
* Followings instructions are there
  - BNEQZ, BEQZ

## 5. Hazard Handling

In a pipelined processor, multiple instructions are executed simultaneously in different stages. This overlapping can lead to **hazards**, where instructions interfere with each other and may produce incorrect results if not handled properly.

In this design, hazards are handled using:
* Forwarding (bypassing)
* Stalling (pipeline pause)
* Flushing (removing incorrect instructions)



### i. Data Hazards

A data hazard occurs when an instruction depends on the result of a previous instruction that has not yet completed execution.

#### Example:
ADD R1, R2, R3

SUB R4, R1, R5



### A. Forwarding (Bypassing)

Forwarding is used to directly transfer data from later pipeline stages to earlier stages without waiting for the write-back stage.

#### Implementation Details:
* The processor compares:
  - Destination register of instruction in EX/MEM stage
  - Destination register of instruction in MEM/WB stage
  - With source registers of the current instruction in ID/EX stage

#### Forwarding Paths:
* EX/MEM → EX (Highest Priority)
  - If the previous instruction has already computed the result, it is forwarded directly to ALU input
* MEM/WB → EX
  - If the value is not available in EX/MEM but available in MEM/WB, it is forwarded

#### Control Signals:
* forwardA and forwardB are used to select ALU inputs:
  - Register file output
  - EX/MEM result
  - MEM/WB result

#### Important Note:
* EX/MEM forwarding is given higher priority than MEM/WB
* This ensures the most recent value is used


### B. Load-Use Hazard (Stalling)

Forwarding cannot resolve hazards when data is not yet available, especially in load instructions.

#### Example:
LW R1, 0(R2)

ADD R3, R1, R4


#### Problem:
* LW gets data in MEM stage
* ADD needs it in EX stage → too early

#### Solution: Stall the Pipeline

* Hazard is detected in ID stage
* If dependency is found:
  - Insert a NOP (bubble)
  - Freeze:
    - Program Counter (PC)
    - IF/ID pipeline register

#### Effect:
* Pipeline pauses for one cycle
* Execution resumes once data is available



### ii. Control Hazards

Control hazards occur due to branch instructions where the next instruction depends on a condition.

#### Example: BEQZ R1, LABEL



### A. Branch Prediction

Instead of waiting for branch resolution, the processor predicts the outcome and continues execution.

#### Branch History Table (BHT):
* Stores a 2-bit saturating counter for each branch
* Indexed using lower bits of PC

#### Prediction Rule:
* MSB of counter:
  - 1 → predict taken
  - 0 → predict not taken

#### Counter Behavior:
* Increment when branch is taken
* Decrement when not taken
* Saturates at 00 and 11



### B. Branch Target Buffer (BTB)

* Stores previously computed branch target addresses
* Used in IF stage to jump to predicted target
* Reduces branch delay



### C. Misprediction Handling (Pipeline Flush)

If prediction is incorrect:

#### Detection:
* Done in EX stage
* Condition:
  predicted ≠ actual

#### Actions:
* FLUSH signal is generated
* Instructions in IF and ID stages are replaced with NOP
* Program Counter (PC) is updated with correct target

#### Result:
* Incorrect instructions are removed
* Execution continues correctly



### iii. Pipeline Control Signals

The following signals are used:

* stall
  - Stops PC and IF stage
  - Used in load-use hazard

* forwardA, forwardB
  - Select forwarded data for ALU inputs

* FLUSH
  - Clears incorrect instructions after branch misprediction

* PC_write
  - Ensures correct PC update



### Summary

* Data hazards are handled using forwarding and stalling
* Control hazards are handled using branch prediction and flushing
* These mechanisms ensure correct execution with minimal performance loss


## 6. Performance Analysis and Results

To evaluate the efficiency of the pipelined processor, several performance counters are implemented in the design. These counters help in understanding how the pipeline behaves under different conditions.


### i. Performance Metrics

The following metrics are measured during execution:

* Total Cycles  
  - Counts the total number of clock cycles taken to execute the program  

* Instruction Count  
  - Counts only valid instructions that successfully complete execution using valid-bit tracking  

* Stall Count  
  - Number of cycles where pipeline is stalled due to data hazards (mainly load-use hazard)  

* Branch Count  
  - Total number of branch instructions executed  

* Misprediction Count  
  - Number of times branch prediction was incorrect  

* CPI (Cycles Per Instruction)  
  - Calculated as:  
    CPI = Total Cycles / Total Instructions  



### ii. Observations

#### 1. Ideal Case (No Hazards)

* No stalls occur  
* No branch mispredictions  
* Pipeline executes efficiently  
* CPI approaches close to 1 after pipeline fill  


#### 2. Data Hazard Case

* Forwarding resolves most data hazards without stalling  
* ALU-to-ALU dependencies are handled efficiently using EX/MEM and MEM/WB forwarding  
* Load-use hazards require one stall cycle because data is not available immediately  
* This slightly increases CPI  



#### 3. Control Hazard Case

* Branch instructions introduce control hazards  
* Branch prediction allows pipeline to continue execution without waiting  
* Misprediction causes pipeline flush, increasing cycle count  


### iii. Branch Prediction Analysis

* A 2-bit saturating counter is used for prediction  
* Predictor learns branch behavior over time  
* Loop-type branches are predicted efficiently after initial iterations  

#### Comparison:

| Predictor Type | Mispredictions | Performance |
|---------------|---------------|------------|
| 1-bit Predictor | Higher | Less stable |
| 2-bit Predictor | Lower | More stable |



### iv. Sample Results

* Total Cycles        ≈ 25  
* Total Instructions  ≈ 20–21  
* Stalls              ≈ 1  
* Branches            ≈ 20  
* Mispredictions      ≈ 1  
* CPI                 ≈ 1.1 – 1.3  


### v. Key Insights

* Pipeline achieves near-ideal performance for long programs  
* Forwarding eliminates most data hazards  
* Stalling is required only for load-use hazards  
* Branch prediction significantly reduces control hazard penalties  
* CPI is higher for short programs due to pipeline fill and drain overhead  



## 7. Conclusion

This project demonstrates the design and implementation of a 32-bit pipelined MIPS processor with realistic features used in modern processors.

The processor successfully handles:

* Data hazards using forwarding and stalling  
* Control hazards using branch prediction and flushing  
* Efficient instruction execution through pipelining  

The addition of performance counters provides deeper insight into processor behavior and efficiency.

Overall, this project builds a strong understanding of:

* Pipeline architecture  
* Hazard handling techniques  
* Branch prediction mechanisms  
* Performance evaluation of processors  

This design can be further extended by adding advanced predictors, cache memory, and modular architecture for scalability.

## 👨‍💻 Author

**Hartik Rai**  
B.Tech, Electronics and Communication Engineering  
NIT Jalandhar  

- 📧 Email: hartikrai332@gmail.com  
- 🔗 LinkedIn: https://www.linkedin.com/in/hartikrai22/  
- 💻 GitHub: https://github.com/Hartik-22  

---

 Feel free to explore, fork, and contribute!
