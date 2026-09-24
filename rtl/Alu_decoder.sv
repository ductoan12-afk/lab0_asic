`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 10:43:39 AM
// Design Name: Nguyen Duc Toan
// Module Name: Alu_decoder
// Project Name: RV32I
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Alu_decoder(
    input logic opb5, // instr[5] ?? phân bi?t I-R format
    input logic [2:0] funct3, // instr[14:12]
    input logic funct7, // instr[30] , ch? c?n bit 30 ?? phân bi?t funct7
    input logic [1:0] alu_op, // tín hi?u t? main decoder
    output logic [3:0] ALUcontrol // tín hi?u t? alu
    );
    
    always_comb begin
        case(alu_op)
            // Kh?i x? lí cho l?nh LOAD/STORE
            2'b00 : ALUcontrol = 4'b0000; // s? d?ng l?nh add ?? tính EA 
            
            // KH?i x? lí cho các l?nh branch            
            2'b01: begin
                case(funct3)
                    3'b000,3'b001 : ALUcontrol = 4'b0001; // BEQ,BNE  dùng phép sub, Zero ?? phân bi?t
                    3'b100,3'b101 : ALUcontrol = 4'b0101; // BLT,BGE   dùng SLT k?t h?p thêm ph?n taken_branch ? file t?ng control ?? phân bi?t
                    3'b110,3'b111 : ALUcontrol = 4'b1000; // BLTU,BGEU  dùng SLTU
                    default : ALUcontrol = 4'b0001;
                endcase     
            end
            
            //Kh?i ALU R I
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (opb5 && funct7) 
                            ALUcontrol = 4'b0001; // SUB
                        else                 
                            ALUcontrol = 4'b0000; // ADD / ADDI
                    end
                    3'b001:  ALUcontrol = 4'b0110; // SLL / SLLI
                    3'b010:  ALUcontrol = 4'b0101; // SLT / SLTI
                    3'b011:  ALUcontrol = 4'b1000; // SLTU / SLTUI
                    3'b100:  ALUcontrol = 4'b0100; // XOR / XORI
                    3'b101: begin
                        if (funct7)
                            ALUcontrol = 4'b0111; // SRA / SRAI
                        else
                            ALUcontrol = 4'b1001; // SRL / SRLI
                    end
                    3'b110:  ALUcontrol = 4'b0011; // OR / ORI
                    3'b111:  ALUcontrol = 4'b0010; // AND / ANDI
                    default: ALUcontrol = 4'b0000;
                endcase
            end            
        default: ALUcontrol = 4'b0000;
        endcase

    end
endmodule
