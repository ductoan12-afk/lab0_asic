
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 08:55:14 AM
// Design Name: Nguyen Duc Toan
// Module Name: Register_file
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


module Register_file(
    input logic clk,
    input logic we3,  // RegWriteW(WB) -> Thanh ghi
    input logic [4:0] a1,a2,a3, // lan luot rs1,rs2,rd
    input logic [31:0] wd3, //ghi d? li?u vào rd
    output logic [31:0] rd1,rd2  // giá tr? ??c c?a rs1,rs2
    );
    
    logic [31:0] register [31:0]; // cau hinh 32 thanh ghi, moi thanh ghi 32 bit

    // KHOI TAO BAN DAU: Xóa toàn b? giá tr? X trong m?ng thanh ghi khi b?t ??u Simulation
    initial begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            register[i] = 32'd0;
        end
    end

    
    // khoi ghi lai tu wb -> thanh ghi
    always_ff @(negedge clk) begin // dung clk am de tranh loi Raw hazard
        if(we3 && (a3 != 5'd0)) begin
            register[a3] <= wd3;
        end
    end
    
// N?u ?ang ghi vào a3 trùng v?i a1/a2 ?ang ??c (và we3 = 1) -> Cho phép l?y th?ng wd3 ra ngay!
    assign rd1 = (a1 == 5'd0) ? 32'd0 : ((a1 == a3) && we3) ? wd3 : register[a1];
    assign rd2 = (a2 == 5'd0) ? 32'd0 : ((a2 == a3) && we3) ? wd3 : register[a2];
endmodule
