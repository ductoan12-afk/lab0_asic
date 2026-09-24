`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 04:39:59 PM
// Design Name: Nguyen Duc Toan
// Module Name: Instruction_memory
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


module Instruction_memory(
    input logic [31:0] a, // Dia chi lenh tu PC_present
    output logic [31:0] rd // Ma may tu dia chi dia chi PC_present
    );
    
    // define mang bo nho ROM 64 cau lenh,  RV32I toi da hon 1 ty cau lenh
    logic [31:0] ROM[1023:0];
    
    initial begin
        $readmemh("test_alu.hex", ROM); 
    end
    
    assign rd = ROM[a[31:2]];  // dich bit sang trai 2 bit la so dia chi chia 4.
endmodule
