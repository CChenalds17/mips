`include "cpu.svh"


module controller
    (
        input logic clk, clk_en, rst,
        input logic [5:0] opcode, funct,
        input logic zero,
        // R-type
        output logic ALUSrcA,
        output logic [1:0] ALUSrcB,
        output logic ShiftSel,
        output logic [3:0] ALUControl,
        output logic IRWrite, RegWrite,
        // I-, J-type
        output logic IorD, ExtSel,
        output logic [1:0] MemtoReg, RegDst, PCSrc,
        output logic PCEn, MemWrite, PCPlus4Write
    );
    
    // intermediate signals
    logic [1:0] ALUOp;
    logic PCWrite, BranchEq, BranchNe;
    logic shouldBranch;
    
    // control_fsm
    control_fsm u_cfsm(
        .clk(clk), .clk_en(clk_en), .rst(rst),
        .opcode(opcode), .funct(funct),
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .ALUOp(ALUOp),
        .PCWrite(PCWrite), .IRWrite(IRWrite), .RegWrite(RegWrite),
        .IorD(IorD), .ExtSel(ExtSel),
        .MemtoReg(MemtoReg), .RegDst(RegDst), .PCSrc(PCSrc),
        .MemWrite(MemWrite), .PCPlus4Write(PCPlus4Write), .BranchEq(BranchEq), .BranchNe(BranchNe)
    );
    
    assign shouldBranch = zero? BranchEq : BranchNe; // shouldBranch logic
    assign PCEn = PCWrite || shouldBranch;
    
    // alu_decoder
    alu_decoder u_decoder(
        .ALUOp(ALUOp), .opcode(opcode), .funct(funct),
        .ALUControl(ALUControl), .ShiftSel(ShiftSel)
    );
endmodule
