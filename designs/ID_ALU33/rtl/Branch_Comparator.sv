`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2026 11:12:09 AM
// Design Name: Nguyen Duc Toan
// Module Name: Branch_Comparator
// Project Name: CPU C
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


module Branch_Comparator(
    input logic [31:0] Src1D,
    input logic [31:0] Src2D,
    output logic    EqualD, // phuc vu cho BEQ,BNE
    output logic    LessSignedD, // phuc vu cho BLT,BGE
    output logic    LessUnsignedD // phuc vu cho BLTU,BGEU
    );
    
    // BEQ,BNE
    assign EqualD = (Src1D == Src2D);
    
    // BLT,BGE
    assign LessSignedD = ($signed(Src1D) < $signed(Src2D));
    
    // BLTU,BGEU
    assign LessUnsignedD = (Src1D < Src2D);
endmodule
