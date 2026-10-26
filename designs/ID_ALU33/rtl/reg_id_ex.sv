`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2026 05:24:43 PM
// Design Name: Nguyen Duc Toan
// Module Name: reg_id_ex
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


module reg_id_ex(
    input logic clk,reset,
    input logic CLR,
    // Tin hieu dieu khien (Control Unit)
    input logic regwriteD,
    input logic [1:0] result_srcD,
    input logic mem_writeD,
    input logic jumpD,
    input logic branchD,
    input logic [3:0] ALUcontrolD,
    input logic alu_srcD,
    input logic [2:0] ImmSrcD,
    
    // Tin hieu du lieu, dia chi (dau vao ID/EX)
    input logic [31:0] rd1D,rd2D,
    input logic [31:0] PCD,
    input logic [4:0] Rs1D,Rs2D,
    input logic [4:0] RdD,
    input logic [31:0] ImmExtD,
    input logic [31:0] PCPlus4D,
    input logic [2:0] funct3D,
    
    // Tin hieu dau ra (ID/EX)
    output logic regwriteE,
    output logic [1:0] result_srcE,
    output logic mem_writeE,
    output logic jumpE,
    output logic branchE,
    output logic [3:0] ALUcontrolE,
    output logic alu_srcE,
    output logic [2:0] ImmSrcE,
    output logic [31:0] rd1E,rd2E,
    output logic [31:0] PCE,
    output logic [4:0] Rs1E,Rs2E,
    output logic [4:0] RdE,
    output logic [31:0] ImmExtE,
    output logic [31:0] PCPlus4E,
    output logic [2:0] funct3E
    );
    always_ff @(posedge clk or posedge reset) begin
        // Reset lai tin hieu 
        if(reset) begin
            regwriteE <= 1'd0;
            result_srcE <= 2'd0;
            mem_writeE <= 1'd0;
            jumpE <= 1'd0;
            branchE <= 1'd0;
            ALUcontrolE <= 4'd0;
            alu_srcE <= 1'd0;
            ImmSrcE <= 3'b000;
            rd1E <= 32'd0;
            rd2E <= 32'd0;
            PCE <= 32'd0;
            Rs1E <= 5'd0;
            Rs2E <= 5'd0;
            RdE <= 5'd0;
            ImmExtE <= 32'd0;
            PCPlus4E <= 32'd0;
            funct3E     <= 3'b0;
        end
        // Flush (xoa cac du lieu o tang ID)
        else if(CLR) begin
            regwriteE <= 1'd0;
            result_srcE <= 2'd0;
            mem_writeE <= 1'd0;
            jumpE <= 1'd0;
            branchE <= 1'd0;
            ALUcontrolE <= 4'd0;
            alu_srcE <= 1'd0;
            ImmSrcE <= 3'b000;
            rd1E <= 32'd0;
            rd2E <= 32'd0;
            PCE <= 32'd0;
            Rs1E <= 5'd0;
            Rs2E <= 5'd0;
            RdE <= 5'd0;
            ImmExtE <= 32'd0;
            PCPlus4E <= 32'd0; 
            funct3E     <= 3'b0;   
        end
        else begin
            regwriteE <= regwriteD;
            result_srcE <= result_srcD;
            mem_writeE <= mem_writeD;
            jumpE <= jumpD;
            branchE <= branchD;
            ALUcontrolE <= ALUcontrolD;
            alu_srcE <= alu_srcD;
            ImmSrcE <= ImmSrcD;
            rd1E <= rd1D;
            rd2E <= rd2D;
            PCE <= PCD;
            Rs1E <= Rs1D;
            Rs2E <= Rs2D;
            RdE <= RdD;
            ImmExtE <= ImmExtD;
            PCPlus4E <= PCPlus4D;  
            funct3E     <= funct3D;          

        end    
    end
endmodule
