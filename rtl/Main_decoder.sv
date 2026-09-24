`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 09:39:00 AM
// Design Name: Nguyen Duc Toan
// Module Name: Main_decoder
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

// Kh?i gi?i mã opcode ?? xác ??nh format và ?i?u khi?n các dây control
module Main_decoder(
    input logic [6:0] opcode, 
    output logic reg_write, // cho phép ghi l?i vào thanh ghi
    output logic [2:0] ImmSrc, // do 5 tr??ng h?p immediate m? rông cua 5 format
    output logic alu_src, // ?i?u khi?n mux2:1 ?? ch?n rs2
    output logic mem_write, // cho phép ghi vào RAM
    output logic [1:0] result_src, // ch?n ki?u d? li?u ghi l?i vào thanh ghi
    output logic branch, // cho phép r? nhánh
    output logic jump, // cho phép nh?y không ?i?u ki?n
    output logic [1:0] alu_op // mã ch? thi ? alu_decode
    );
    
    logic [11:0] controls; // tín hi?u 12 bit
    // ép v? 1 controls ?i?u khi?n 12 bit output
    assign {reg_write,ImmSrc,alu_src,mem_write,result_src,branch,jump,alu_op} = controls;
    
    always_comb begin
        case(opcode)
            // R_type   , x dont care dù tr??ng h?p 0 hay 1 thì không ?nh h??ng 
            7'b0110011 : controls = 12'b1_000_0_0_00_0_0_10;
            // I_type
            7'b0010011 : controls = 12'b1_000_1_0_00_0_0_10;
            // Load (lw)
            7'b0000011 : controls = 12'b1_000_1_0_01_0_0_00;

            // Store (sw)
            7'b0100011 : controls = 12'b0_001_1_1_00_0_0_00;

            // Branch 
            7'b1100011 : controls = 12'b0_010_0_0_00_1_0_01;

            // JAL (Jump)
            7'b1101111 : controls = 12'b1_011_0_0_10_0_1_00;

            // U-type 
            7'b0110111 : controls = 12'b1_100_1_0_00_0_0_00;

            // Default: NOP
            default :    controls = 12'b0_000_0_0_00_0_0_00;        
        endcase
    end
endmodule
