`include "cpu.svh"

module cpu
    # ( parameter DATA_WIDTH = 32, 
        parameter ADDR_WIDTH = 5)
    (
        input logic clk, clk_en, rst,
        input logic [31:0] r_data,
        output logic wr_en,
        output logic [31:0] mem_addr, w_data,

        //OK regs
        output logic [DATA_WIDTH-1:0] regs_ok [0:2**ADDR_WIDTH-1]
    );
    
    // Control unit inputs
    logic [5:0] opcode, funct;
    logic zero;
    
    // Control signals
    logic ALUSrcA, ShiftSel;
    logic [1:0] ALUSrcB;
    logic [3:0] ALUControl;
    logic IRWrite, RegWrite;
    logic IorD, ExtSel;
    logic [1:0] MemtoReg, RegDst, PCSrc;
    logic PCEn, MemWrite, PCPlus4Write;

    // DATAPATH (interfaces with main memory with r_data, wr_en, mem_addr, w_data)
    datapath u_datapath(
        .clk(clk), .clk_en(clk_en), .rst(rst),
        .r_data(r_data), .wr_en(wr_en), .mem_addr(mem_addr), .w_data(w_data), // memory
        .ALUSrcA(ALUSrcA), .ShiftSel(ShiftSel), .ALUSrcB(ALUSrcB), .ALUControl(ALUControl), // control selects
        .IRWrite(IRWrite), .RegWrite(RegWrite), // control enables
        .PCEn(PCEn), .MemWrite(MemWrite), .PCPlus4Write(PCPlus4Write),
        .IorD(IorD), .ExtSel(ExtSel), .MemtoReg(MemtoReg), .RegDst(RegDst), .PCSrc(PCSrc),
        .opcode(opcode), .funct(funct), .zero(zero), // control inputs
        .regs_ok(regs_ok)
    );

    // CONTROLLER
    controller u_ctrl(
        .clk(clk), .clk_en(clk_en), .rst(rst),
        .opcode(opcode), .funct(funct), .zero(zero),
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB),
        .ShiftSel(ShiftSel),
        .ALUControl(ALUControl),
        .IRWrite(IRWrite), .RegWrite(RegWrite),
        .IorD(IorD), .ExtSel(ExtSel), .MemtoReg(MemtoReg), .RegDst(RegDst), .PCSrc(PCSrc),
        .PCEn(PCEn), .MemWrite(MemWrite), .PCPlus4Write(PCPlus4Write)
    );
    
endmodule

