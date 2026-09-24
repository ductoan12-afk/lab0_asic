`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2026 05:00:58 PM
// Design Name: Nguyen Duc Toan
// Module Name: reg_if_id
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


module reg_if_id(
    input logic clk, reset,
    input logic EN,
    input logic CLR,
    
    // Input vao tang IF
    input logic [31:0] InstrF,
    input logic [31:0] PCF,
    input logic [31:0] PCPlus4F,
    
    // Output ra tang ID
    output logic [31:0] InstrD,
    output logic [31:0] PCD,
    output logic [31:0] PCPlus4D
    );
    
    always_ff @(posedge clk or posedge reset) begin
        // Reset tin hieu 
        if(reset) begin
            InstrD <= 32'd0;
            PCD <= 32'd0;
            PCPlus4D <= 32'd0;
        end
        
        // Flush (xoa du lieu tang IF)
        else if(CLR) begin
            InstrD <= 32'd0;
            PCD <= 32'd0;
            PCPlus4D <= 32'd0;
        end
        
        else if(EN) begin
            InstrD <= InstrF;
            PCD <= PCF;
            PCPlus4D <= PCPlus4F;
        end
        // neu EN = 0 thi output van giu nguyen 
    end
endmodule
