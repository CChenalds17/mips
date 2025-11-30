`include "cpu.svh"


module alu_decoder
    (
        input logic [1:0] ALUOp,
        input logic [5:0] opcode, funct,
        
        output logic [3:0] ALUControl,
        output logic ShiftSel
    );
        
    always_comb begin
        ALUControl = `ALU_ZERO; // outputs 0
        ShiftSel = 1'b0; // defaults to not a shift operation
        
        unique case (ALUOp)
            2'b00: begin
                ALUControl = `ALU_ADD;
            end
            
            2'b01: begin
                ALUControl = `ALU_SUB;
            end
            
            // R-type
            2'b10: begin
                unique case (funct)
                    `F_AND: ALUControl = `ALU_AND;
                    `F_OR: ALUControl = `ALU_OR;
                    `F_XOR: ALUControl = `ALU_XOR;
                    `F_NOR: ALUControl = `ALU_NOR;
                    `F_SLL: begin
                        ALUControl = `ALU_SLL;
                        ShiftSel = 1;
                    end
                    `F_SRL: begin
                        ALUControl = `ALU_SRL;
                        ShiftSel = 1;
                    end
                    `F_SRA: begin
                        ALUControl = `ALU_SRA;
                        ShiftSel = 1;
                    end
                    `F_SLT: ALUControl = `ALU_SLT;
                    `F_ADD: ALUControl = `ALU_ADD;
                    `F_SUB: ALUControl = `ALU_SUB;
                    `F_JR: ALUControl = `ALU_ZERO; // outputs 0
                    default: /* keep defaults */;
                endcase
            end
            
            // I-type
            2'b11: begin
                unique case (opcode)
                    `OP_ANDI: ALUControl = `ALU_AND;
                    `OP_ORI: ALUControl = `ALU_OR;
                    `OP_XORI: ALUControl = `ALU_XOR;
                    `OP_SLTI: ALUControl = `ALU_SLT;
                    `OP_ADDI: ALUControl = `ALU_ADD;
                    default: ;
                endcase
            end
        
            default: /* keep defaults */;
        endcase
    end
    
endmodule