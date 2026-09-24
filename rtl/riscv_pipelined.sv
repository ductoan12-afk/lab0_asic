`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 05:40:25 PM
// Design Name: Nguyen Duc Toan
// Module Name: riscv_pipelined
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

// DATAPATH
module riscv_pipelined(
    input logic clk,reset,
    input logic PCSrc,

    // Instruction Memory
    output logic [31:0] PCF,
    input logic [31:0] InstrF,
    
    // Data Memory
    output logic [31:0] ALUresultM,
    output logic [31:0] WriteDataM,
    output logic mem_writeM,
    input logic [31:0] ReadDataM,
    
    // Control Unit
    input logic regwriteD,
    input logic [1:0] result_srcD,
    input logic memwriteD,
    input logic jumpD,
    input logic branchD,
    input logic [3:0] ALUcontrolD,
    input logic alu_srcD,
    input logic [2:0] ImmSrcD,
    output logic [31:0] InstrD, // xuat lenh tu tang ID ra controller de giai ma
    output logic  ZeroE,
    output logic  LessE,
    output logic [31:0] ALUResultE,
    output logic branchE,
    output logic jumpE,
    output logic [2:0] funct3E
    );
    
    // Khai bao cac duong day noi bo
    // Tang IF
    logic [31:0] PCNextF, PCPlus4F;
    
    // Tang ID
    logic [31:0] rd1D,rd2D;
    logic [31:0] PCD;
    logic [4:0] Rs1D,Rs2D,RdD;
    logic [31:0] ImmExtD;
    logic [31:0] PCPlus4D;
    
    // Tang EX
    logic regwriteE;
    logic [1:0] result_srcE;
    logic memwriteE;
    logic [3:0] ALUcontrolE;
    logic alu_srcE;
    logic [2:0] ImmSrcE;
    logic [31:0] rd1E,rd2E,PCE,ImmExtE,PCPlus4E;
    logic [31:0] WriteDataE,SrcA,SrcB,PCTargetE;
    logic [4:0] Rs1E,Rs2E,RdE;
    logic PCSrcE;
    
    // Tang MEM
    logic regwriteM;
    logic [1:0] result_srcM;
    logic [4:0] RdM;
    logic [31:0] PCPlus4M;
    
    // Tang WB
    logic regwriteW;
    logic [31:0] ALUresultW,ReadDataW,PCPlus4W;
    logic [1:0] result_srcW;
    logic [31:0] ResultW;
    logic [4:0] RdW;
    
    // Hazard Unit
    logic StallF,StallD,FlushD,FlushE;
    logic [1:0] ForwardA,ForwardB;
    
    // Tang 1(IF)
    
    // MUX chon PCnext
    mux2 #(.WIDTH(32)) pc_next_mux (
        .d0(PCPlus4F),
        .d1(PCTargetE),
        .sel(PCSrcE),
        .y(PCNextF)   
    );
    // Thanh ghi PC
    always_ff @(posedge clk or posedge reset) begin
        if(reset)
            PCF <= 32'd0;
        else if(!StallF) 
            PCF <= PCNextF;    
    end
    
    // Bo cong Adder -> PCPlus4F
    adder #(.WIDTH(32)) adderF(
        .d0(PCF),
        .d1(32'd4),
        .y(PCPlus4F) 
    );
    
    // PIPELINE 1(IF/ID)
    reg_if_id reg_id_if_pipeline(
        .clk(clk),.reset(reset),
        .EN(!StallD),.CLR(FlushD),
        .InstrF(InstrF),.PCF(PCF),
        .PCPlus4F(PCPlus4F),.InstrD(InstrD),
        .PCD(PCD),.PCPlus4D(PCPlus4D)
    );
    
    // Tang 2(ID)
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD = InstrD[11:7];
    
    Register_file Register_fileD(
        .clk(clk),.we3(regwriteW),
        .a1(Rs1D),.a2(Rs2D),
        .a3(RdW),.wd3(ResultW),
        .rd1(rd1D),.rd2(rd2D)
    );
    
    extend extendD(
        .Instr(InstrD[31:7]),
        .ImmSrc(ImmSrcD),
        .ImmExt(ImmExtD)
    );
    
    // PIPELINE 2(ID/EX)
    reg_id_ex reg_id_ex_pipeline(
        .clk(clk),.reset(reset),.CLR(FlushE),
        .regwriteD(regwriteD),.result_srcD(result_srcD),.mem_writeD(memwriteD),
        .jumpD(jumpD),.branchD(branchD),.ALUcontrolD(ALUcontrolD),
        .alu_srcD(alu_srcD),.ImmSrcD(ImmSrcD),.rd1D(rd1D),.rd2D(rd2D),.PCD(PCD),
        .Rs1D(Rs1D),.Rs2D(Rs2D),.RdD(RdD),.ImmExtD(ImmExtD),.PCPlus4D(PCPlus4D),
        .funct3D(InstrD[14:12]),
        
        .regwriteE(regwriteE),.result_srcE(result_srcE),.mem_writeE(memwriteE),
        .jumpE(jumpE),.branchE(branchE),.ALUcontrolE(ALUcontrolE),.alu_srcE(alu_srcE),.ImmSrcE(ImmSrcE),
        .rd1E(rd1E),.rd2E(rd2E),.PCE(PCE),.Rs1E(Rs1E),.Rs2E(Rs2E),
        .RdE(RdE),.ImmExtE(ImmExtE),.PCPlus4E(PCPlus4E),.funct3E(funct3E)
    );
    
    
    // Tang 3(EX)
    // MUX 3:1 A
    logic [31:0] SrcAForwarded;

    mux3 #(.WIDTH(32)) forwardA_mux(
        .d0(rd1E),
        .d1(ResultW),
        .d2(ALUresultM),
        .sel(ForwardA),
        .y(SrcAForwarded)
    );
    assign SrcA = (ImmSrcE == 3'b100) ? 32'd0 : SrcAForwarded;
    
    // MUX 3:1 B
    mux3 #(.WIDTH(32)) forwardB_mux(
        .d0(rd2E),
        .d1(ResultW),
        .d2(ALUresultM),
        .sel(ForwardB),
        .y(WriteDataE)  
    );
    
    // MUX 3:1 chon SrcB
    mux2 #(.WIDTH(32)) MUX2_ALUsrcE(
        .d0(WriteDataE),
        .d1(ImmExtE),
        .sel(alu_srcE),
        .y(SrcB)
    );
    
    // ALU unit
    alu ALU_UNIT(
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUcontrol(ALUcontrolE),
        .ALUresult(ALUResultE),
        .Zero(ZeroE),
        .Less(LessE)
    );
    
    // Bo cong nhay ( adder immediate)
    adder #(.WIDTH(32)) Adder_imm(
        .d0(PCE),
        .d1(ImmExtE),
        .y(PCTargetE)
    );
    assign PCSrcE = PCSrc; // tin hieu tu controller
    
    // PIPELINE 3(EX/MEM)
    reg_ex_mem reg_ex_mem_pipeline(
        .clk(clk),.reset(reset),.regwriteE(regwriteE),
        .result_srcE(result_srcE),.mem_writeE(memwriteE),
        .ALUresultE(ALUResultE),.WriteDataE(WriteDataE),
        .PCPlus4E(PCPlus4E),.RdE(RdE),.regwriteM(regwriteM),
        .result_srcM(result_srcM),.mem_writeM(mem_writeM),
        .ALUresultM(ALUresultM),.WriteDataM(WriteDataM),
        .PCPlus4M(PCPlus4M),.RdM(RdM)
    );
    
    // Tang 4(MEM)
    // PIPELINE 4(MEM/WB)
    reg_mem_wb reg_mem_wb_pipeline(
        .clk(clk),.reset(reset),.regwriteM(regwriteM),
        .result_srcM(result_srcM),.RAM_RD(ReadDataM),
        .ALUresultM(ALUresultM),.RdM(RdM),.PCPlus4M(PCPlus4M),
        .regwriteW(regwriteW),.result_srcW(result_srcW),.ALUresultW(ALUresultW),
        .ReadDataW(ReadDataW),.RdW(RdW),.PCPlus4W(PCPlus4W)
    );
    
    // Tang 5(WB)
    mux3 #(.WIDTH(32)) MUX3_ResultW(
        .d0(ALUresultW),
        .d1(ReadDataW),
        .d2(PCPlus4W),
        .sel(result_srcW),
        .y(ResultW)    
    );
    
    // Hazard Unit
    Hazard_Unit Hazard_Unit_datapath(
        .Rs1D(Rs1D),.Rs2D(Rs2D),.Rs1E(Rs1E),.Rs2E(Rs2E),
        .RdE(RdE),.RdM(RdM),.RdW(RdW),.regwriteM(regwriteM),
        .regwriteW(regwriteW),.result_srcE(result_srcE),
        .PCsrcE(PCSrcE),.StallF(StallF),.StallD(StallD),
        .FlushD(FlushD),.FlushE(FlushE),.ForwardA(ForwardA),.ForwardB(ForwardB)
    );
endmodule
