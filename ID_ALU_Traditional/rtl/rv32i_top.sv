`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2026 08:43:05 AM
// Design Name: Nguyen Duc Toan
// Module Name: rv32i_top
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


module rv32i_top(
    input logic clk,
    input logic reset,
    
    // Cac tin hieu check/debug
    output logic [31:0] WriteDataM,
    output logic [31:0] ALUresultM,
    output logic mem_writeM
    );
    
    // Datapath - Instruction Memory
    logic [31:0] PCF;
    logic [31:0] InstrF;
    
    // Datapath - Data Memory
    logic [31:0] ReadDataM;
    
    // Datapath - Controller
    logic [31:0] InstrD;
    logic regwriteD;
    logic [1:0] result_srcD;
    logic memwriteD;
    logic jumpD;
    logic branchD;
    logic [3:0] ALUcontrolD;
    logic alu_srcD;
    logic [2:0] ImmSrcD;
    // ID comparator
    logic EqualD;
    logic LessSignedD;
    logic LessUnsignedD;

    logic BranchTakenD;
    // PC 
    logic PCSrcD;
    logic PCSrcE;
    
    logic  ZeroE;
    logic LessE;
    logic [31:0] ALUResultE;
    
    logic branchE;
    logic jumpE;
    logic [2:0] funct3E;
    logic [2:0] funct3M;    
    // Khoi tao Datapath
    riscv_pipelined Datapath(
        .clk(clk),.reset(reset),.PCSrcE(PCSrcE),.PCSrcD(PCSrcD),
        
        // Instruction memory
        .PCF(PCF),.InstrF(InstrF),
        
        // Data memory
        .ALUresultM(ALUresultM),.WriteDataM(WriteDataM),
        .mem_writeM(mem_writeM),.ReadDataM(ReadDataM),
        
        //Control unit
        .regwriteD(regwriteD),.result_srcD(result_srcD),
        .memwriteD(memwriteD),.jumpD(jumpD),.branchD(branchD),
        .ALUcontrolD(ALUcontrolD),.alu_srcD(alu_srcD),
        .ImmSrcD(ImmSrcD),.InstrD(InstrD),.EqualD(EqualD),
        .LessSignedD(LessSignedD),.LessUnsignedD(LessUnsignedD),.ZeroE(ZeroE),.LessE(LessE),.ALUResultE(ALUResultE),
        .branchE(branchE),.jumpE(jumpE),.funct3E(funct3E),.funct3M(funct3M)
    );
    
    // Khoi tao Controller
    Controller Controller_unit(
        .opcode(InstrD[6:0]),
        .funct3D(InstrD[14:12]),
        .funct7(InstrD[30]),
        .EqualD(EqualD),
        .LessSignedD(LessSignedD),
        .LessUnsignedD(LessUnsignedD),
        .jumpE(jumpE),
        .regwriteD(regwriteD),
        .ImmSrcD(ImmSrcD),
        .alu_srcD(alu_srcD),
        .memwriteD(memwriteD),
        .result_srcD(result_srcD),
        .branchD(branchD),
        .jumpD(jumpD),
        .ALUcontrolD(ALUcontrolD),
        .BranchTakenD(BranchTakenD),
        .PCSrcD(PCSrcD),
        .PCSrcE(PCSrcE)
    );
    
    // Khoi tao Instruction memory
    Instruction_memory Instruction_memory_unit(
        .a(PCF),.rd(InstrF)
    );
    
    // Khoi tao Data memory
    Data_memory Data_memory_unit(
        .clk(clk),.we(mem_writeM),
        .A(ALUresultM),.wd(WriteDataM),.funct3(funct3M),.RD(ReadDataM)
    );
    
endmodule
