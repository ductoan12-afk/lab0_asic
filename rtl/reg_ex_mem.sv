`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 09:29:22 AM
// Design Name: Nguyen Duc Toan
// Module Name: reg_ex_mem
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


module reg_ex_mem(
    input logic clk,reset,

    // input dau vao tang EX/MEM
    input logic regwriteE,
    input logic [1:0] result_srcE,
    input logic mem_writeE,
    input logic [31:0] ALUresultE,
    input logic [31:0] WriteDataE,
    input logic [31:0] PCPlus4E,
    input logic [4:0] RdE,
    
    // output cua tang EX/MEM
    output logic regwriteM,
    output logic [1:0] result_srcM,
    output logic mem_writeM,
    output logic [31:0] ALUresultM,
    output logic [31:0] WriteDataM,
    output logic [31:0] PCPlus4M,
    output logic [4:0] RdM
    );
    
    always_ff @(posedge clk or posedge reset) begin
        // Reset tin hieu
        if(reset) begin
            regwriteM <= 1'd0;
            result_srcM <= 2'd0;
            mem_writeM <= 1'd0;
            ALUresultM <= 32'd0;
            WriteDataM <= 32'd0;
            PCPlus4M <= 32'd0;
            RdM <= 5'd0;       
        end
        else begin
            regwriteM <= regwriteE;
            result_srcM <= result_srcE;
            mem_writeM <= mem_writeE;
            ALUresultM <= ALUresultE;
            WriteDataM <= WriteDataE;
            PCPlus4M <= PCPlus4E;
            RdM <= RdE;
        end
    end
endmodule
