# MIPS Multicycle Processor

This project implements a multicycle MIPS processor in SystemVerilog, supporting a subset of R-, I-, and J-type instructions. The design includes a custom FSM-based control unit and a multistage datapath constructed using the ALU, register file, and memory modules. I extended the control logic to handle arithmetic, logic, branching, memory access, and jump instructions, and ensured correct sequencing across multicycle execution states.

The processor was tested through simulation using custom assembly programs and then deployed to an FPGA, where instructions and data were loaded via a Python-based interface. This project provided hands-on experience with CPU control design, digital logic, and FPGA development.

Schematics for the Datapath can be found in `processor.pdf`, and the control unit FSM can be found in `FSM.pdf`
