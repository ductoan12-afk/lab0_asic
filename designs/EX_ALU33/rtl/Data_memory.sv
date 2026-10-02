`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/14/2026 07:42:27 AM
// Design Name: Nguyen Duc Toan
// Module Name: Data_memory
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


module Data_memory(
    input logic clk,
    input logic we, // Tin hieu cho phep ghi vao RAM, MemWrite
    input logic [31:0] A, // ALUResult
    input logic [31:0] wd, // Du lieu can ghi vào RAM
    output logic [31:0] RD // Du lieu can doc ra tu RAM
    );
    
    // Khai bao dung luong RAM
    logic [31:0] RAM[63:0];
    // Du lieu doc(bat dong bo), thay doi ngay khi co A
    
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            RAM[i] = 32'd0; // Gán toàn b? ô nh? ban ??u b?ng 0
        end
    end
    assign RD = RAM[A[31:2]];
    
    // Du lieu ghi vao RAM(dong bo voi clk)
    always_ff @(posedge clk) begin
        if(we)
            RAM[A[31:2]] <= wd;
    end
endmodule
