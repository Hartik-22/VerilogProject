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




