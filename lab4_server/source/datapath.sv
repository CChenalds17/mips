`include "cpu.svh"


module datapath
    # ( parameter DATA_WIDTH = 32, 
        parameter ADDR_WIDTH = 5)
    (
        input logic clk, clk_en, rst,
        
        // memory
        input logic [31:0] r_data,
        output logic wr_en,
        output logic [31:0] mem_addr, w_data,
        
        // control inputs (R)
        input logic IRWrite, RegWrite, ALUSrcA, ShiftSel,
        input logic [1:0] ALUSrcB,
        input logic [3:0] ALUControl,
        // control inputs (I, J)
        input logic PCEn, MemWrite, PCPlus4Write,
        input logic IorD, ExtSel, 
        input logic [1:0] MemtoReg, RegDst, PCSrc,

        // status outputs to control
        output logic [5:0] opcode, funct,
        output logic zero,
        
        // OK debug
        output logic [DATA_WIDTH-1:0] regs_ok [0:2**ADDR_WIDTH-1]
    );
    
    // PC, IR REGISTERS
    
    // inputs & outputs
    logic [31:0] PC_q, PC_d;
    logic [31:0] IR_q, IR_d;
    
    reg_en #(.INIT(`I_START_ADDRESS)) u_pc (
        .clk(clk), .clk_en(clk_en), .rst(rst),
        .en(PCEn), .d(PC_d), .q(PC_q)
    );
    reg_en u_ir(
        .clk(clk), .clk_en(clk_en), .rst(rst),
        .en(IRWrite), .d(IR_d), .q(IR_q)
    );
    
    // MDR REGISTER
    logic [31:0] MDR_d, MDR_q;
    reg_reset u_mdr(
        .clk(clk), .clk_en(clk_en), .rst(rst), .d(MDR_d), .q(MDR_q)
    );
                
    // REGISTER FILE
    
    // rf inputs
    logic [4:0] rf_A1, rf_A2, rf_A3;
    logic [31:0] rf_WD3;
    // rf outputs
    logic [31:0] rf_RD1, rf_RD2;
    
    reg_file u_rf(
        .clk(clk), .clk_en(clk_en),
        .wr_en(RegWrite),
        .r0_addr(rf_A1),
        .r1_addr(rf_A2),
        .w_addr(rf_A3),
        .w_data(rf_WD3),
        .r0_data(rf_RD1),
        .r1_data(rf_RD2),
        .regs_ok(regs_ok)
    );
    
    // EXTENDED VALUES
    logic [31:0] shamt32;
    logic [31:0] SignImm;
    logic [31:0] ZeroImm;
    // intermediate signals
    logic [31:0] ExtImm; // for ExtSel mux
    logic [31:0] BranchOffset; // SignImm << 2
    
    // A, B REGISTERS
    logic [31:0] A_q, A_d;
    logic [31:0] B_q, B_d;
    
    reg_reset u_a(
        .clk(clk), .clk_en(clk_en), .rst(rst), .d(A_d), .q(A_q)
    );
    reg_reset u_b(
        .clk(clk), .clk_en(clk_en), .rst(rst),
        .d(B_d), .q(B_q)
    );
        
    // ALU
    
    // ALU inputs
    logic [31:0] SrcA, SrcB;
    logic [31:0] ALU_A, ALU_B;
    // ALU output
    logic [31:0] ALUResult;
    
    alu u_alu(
        .x(ALU_A), .y(ALU_B),
        .op(ALUControl),
        .z(ALUResult),
        .zero(zero)
    );
    
    // ALUOUT REGISTER
    logic [31:0] ALUOut_q, ALUOut_d;

    reg_reset u_aluout(
        .clk(clk), .clk_en(clk_en), .rst(rst),
        .d(ALUOut_d), .q(ALUOut_q)
    );
    
    // intermediate signal
    logic [31:0] JumpAddr; // for PCSrc mux
    
    // PCPLUS4 REGISTER
    logic [31:0] PCPlus4_d, PCPlus4_q;
    reg_en u_pcplus4(
        .clk(clk), .clk_en(clk_en), .rst(rst), .en(PCPlus4Write), .d(PCPlus4_d), .q(PCPlus4_q)
    );
    
    
    // ASSIGN WIRES
    
        
    // memory inputs
    
    // IorD 2-1 mux
    assign mem_addr = IorD ? ALUOut_q : PC_q;
    
    assign w_data = B_q; // for sw instruction
    assign wr_en = MemWrite;
    
    // IR input
    assign IR_d = r_data;
    
    // MDR input
    assign MDR_d = r_data;
            
    // RF inputs
    assign rf_A1 = IR_q[25:21];
    assign rf_A2 = IR_q[20:16];
    // RegDst 3-1 mux
    assign rf_A3 = (RegDst == 2'b00) ? IR_q[20:16] :
                   (RegDst == 2'b01) ? IR_q[15:11] :
                                       5'd31;
    // MemtoReg 3-1 mux
    assign rf_WD3 = (MemtoReg == 2'b00) ? ALUOut_q :
                    (MemtoReg == 2'b01) ? MDR_q :
                                          PCPlus4_q;
    
    // control unit inputs
    assign opcode = IR_q[31:26];
    assign funct = IR_q[5:0];   
     
    // A, B inputs
    assign A_d = rf_RD1;
    assign B_d = rf_RD2;
    
    // extends
    assign SignImm = { {16{IR_q[15]}}, IR_q[15:0] };
    assign ZeroImm = {16'b0, IR_q[15:0]};
    assign shamt32 = {27'b0, IR_q[10:6]};
    
    assign JumpAddr = {PC_q[31:28], IR_q[25:0], 2'b00};

    // SrcA 2-1 mux
    assign SrcA = ALUSrcA ? A_q : PC_q;
    
    // ExtSel 2-1 mux
    assign ExtImm = ExtSel ? ZeroImm : SignImm;
    
    // left shift 2 for BranchOffset
    assign BranchOffset = {SignImm[29:0], 2'b00}; // SignImm << 2
    
    // SrcB 4-1 mux
    assign SrcB = (ALUSrcB == 2'b00) ? B_q :
                  (ALUSrcB == 2'b01) ? 32'd4 :
                  (ALUSrcB == 2'b10) ? ExtImm :
                                       BranchOffset;
    
    // ALU inputs (ShiftSel muxes for A and B)
    assign ALU_A = ShiftSel ? B_q : SrcA;
    assign ALU_B = ShiftSel ? shamt32 : SrcB;
    
    // ALUOut input
    assign ALUOut_d = ALUResult;
    // PCPlus4 input
    assign PCPlus4_d = ALUResult;
        
    // PC input (PCSrc 4-1 mux)
    assign PC_d = (PCSrc == 2'b00) ? ALUResult :
                  (PCSrc == 2'b01) ? ALUOut_q :
                  (PCSrc == 2'b10) ? JumpAddr :
                                     A_q;
    
endmodule
