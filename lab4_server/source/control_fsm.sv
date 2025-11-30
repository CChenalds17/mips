`include "cpu.svh"


module control_fsm
    (
        input logic clk, clk_en, rst,
        input logic [5:0] opcode, funct,
        
        output logic ALUSrcA,
        output logic [1:0] ALUSrcB,
        output logic [1:0] ALUOp,
        output logic PCWrite, IRWrite, RegWrite,
        output logic IorD, ExtSel,
        output logic [1:0] MemtoReg, RegDst, PCSrc,
        output logic MemWrite, PCPlus4Write, BranchEq, BranchNe
    );
    // FSM states
    typedef enum {
        S_IF,
        S_ID,
        S_EX_R,
        S_WB_R,
        S_EX_JR,
        S_EX_I_A,
        S_EX_I_L,
        S_WB_I,
        S_EX_ADDR,
        S_MEM_RD,
        S_MEM_WR,
        S_WB_LW,
        S_EX_J,
        S_WB_JAL,
        S_EX_BEQ,
        S_EX_BNE
    } state_t;
    
    state_t state, next_state;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S_IF;
        end
        else begin
            state <= next_state;
        end
    end
    
    // next state logic
    always_comb begin
        // defaults
        IorD = 1'b0; 
        MemtoReg = 2'b00;
        RegDst = 2'b01;
        ExtSel = 1'b0;
        ALUSrcA = 1'b0;
        ALUSrcB = 2'b00;
        ALUOp = 2'b10;
        PCSrc = 2'b00;
        MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
        
        unique case (state)
            S_IF: begin
                // IR  = Instr; PC = PC + 4
                IorD = 1'b0;
                ALUSrcA = 1'b0;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                PCSrc = 2'b00;
                
                PCWrite = 1'b1; IRWrite = 1'b1; PCPlus4Write = 1'b1;
                MemWrite=1'b0; RegWrite=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_ID;
            end
            
            S_ID: begin
                ALUSrcA = 1'b0;
                ALUSrcB = 2'b11;
                ALUOp = 2'b00;
                
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                if ((opcode == `OP_RTYPE) && (funct != `F_JR))
                    next_state = S_EX_R;
                else if ((opcode == `OP_RTYPE) && (funct == `F_JR))
                    next_state = S_EX_JR;
                else if ((opcode == `OP_LW) || (opcode == `OP_SW))
                    next_state = S_EX_ADDR;
                else if ((opcode == `OP_SLTI) || (opcode == `OP_ADDI))
                    next_state = S_EX_I_A;
                else if ((opcode == `OP_ANDI) || (opcode == `OP_ORI) || (opcode == `OP_XORI))
                    next_state = S_EX_I_L;
                else if (opcode == `OP_BNE)
                    next_state = S_EX_BNE;
                else if (opcode == `OP_BEQ)
                    next_state = S_EX_BEQ;
                else
                    next_state = S_EX_J;
            end
            
            S_EX_R: begin
                // ALUOut <= ALUResult = A op B
                ALUSrcA = 1;
                ALUSrcB = 2'b00;
                ALUOp = 2'b10;
                
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_WB_R;
            end
            
            S_WB_R: begin
                // $rd <= ALUOut
                RegDst = 2'b01;
                MemtoReg = 2'b00;
                
                RegWrite = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_IF;
            end
            
            S_EX_ADDR: begin
                ExtSel = 1'b0;
                ALUSrcA = 1'b1;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
                
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                if (opcode == `OP_LW)
                    next_state = S_MEM_RD;
                else
                    next_state = S_MEM_WR;
            end
            
            S_MEM_RD: begin
                IorD = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_WB_LW;
            end
            
            S_MEM_WR: begin
                IorD = 1'b1;
                MemWrite = 1'b1;
                IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_IF;
            end
            
            S_WB_LW: begin
                RegDst = 2'b00;
                MemtoReg = 2'b01;
                
                RegWrite = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_IF;
            end
            
            S_EX_JR: begin
                PCSrc = 2'b11;
                PCWrite = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_IF;
            end
            
            S_EX_I_A: begin
                ExtSel = 1'b0;
                ALUSrcA = 1'b1;
                ALUSrcB = 2'b10;
                ALUOp = 2'b11;
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_WB_I;
            end
            
            S_EX_I_L: begin
                ExtSel = 1'b1;
                ALUSrcA = 1'b1;
                ALUSrcB = 2'b10;
                ALUOp = 2'b11;
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_WB_I;
            end
            
            S_WB_I: begin
                RegDst = 2'b00;
                MemtoReg = 2'b00;
                RegWrite = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_IF;
            end
            
            S_EX_BNE: begin
                ALUSrcA = 1'b1;
                ALUSrcB = 2'b00;
                ALUOp = 2'b01;
                PCSrc = 2'b01;
                
                BranchNe = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0;
                
                next_state = S_IF;
            end
            
            S_EX_BEQ: begin
                ALUSrcA = 1'b1;
                ALUSrcB = 2'b00;
                ALUOp = 2'b01;
                PCSrc = 2'b01;
                
                BranchEq = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchNe=1'b0;
                
                next_state = S_IF;
            end
            
            S_EX_J: begin
                PCSrc = 2'b10;
                PCWrite = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; RegWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                if (opcode == `OP_JAL)
                    next_state = S_WB_JAL;
                else
                    next_state = S_IF;
            end
            
            S_WB_JAL: begin
                RegDst = 2'b10;
                MemtoReg = 2'b10;
                RegWrite = 1'b1;
                MemWrite=1'b0; IRWrite=1'b0; PCWrite=1'b0; PCPlus4Write=1'b0; BranchEq=1'b0; BranchNe=1'b0;
                
                next_state = S_IF;
            end            
            
            default: ;
        endcase
    end
    
endmodule
