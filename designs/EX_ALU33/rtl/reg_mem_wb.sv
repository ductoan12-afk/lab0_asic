`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 09:47:48 AM
// Design Name: Nguyen Duc Toan
// Module Name: reg_mem_wb
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


module reg_mem_wb(
    input logic clk,reset,
    
    // Input dau vao MEM/WB
    input logic regwriteM,
    input logic [1:0] result_srcM,
    input logic [31:0] RAM_RD,
    input logic [31:0] ALUresultM,
    input logic [4:0] RdM,
    input logic [31:0] PCPlus4M,
    
    // Output dau ra MEM/WB
    output logic regwriteW,
    output logic [1:0] result_srcW,
    output logic [31:0] ALUresultW,
    output logic [31:0] ReadDataW,
    output logic [4:0] RdW,
    output logic [31:0] PCPlus4W
    );
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            regwriteW <= 1'd0;
            result_srcW <= 2'd0;
            ALUresultW <= 32'd0;
            ReadDataW <= 32'd0;
            RdW <= 5'd0;
            PCPlus4W <= 32'd0;
        end
        
        else begin
            regwriteW <= regwriteM;
            result_srcW <= result_srcM;
            ALUresultW <= ALUresultM;
            ReadDataW <= RAM_RD;
            RdW <= RdM;
            PCPlus4W <= PCPlus4M;
        end     
    end
    
endmodule
