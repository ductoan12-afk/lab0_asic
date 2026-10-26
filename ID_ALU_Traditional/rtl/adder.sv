`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2026 04:20:18 PM
// Design Name: Nguyen Duc Toan
// Module Name: adder
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


module adder #(
    parameter WIDTH = 32 // dung chung 32bit
)(
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    output logic [WIDTH-1:0] y
    );
    
    always_comb begin
        y = d0 + d1;
    
    end
endmodule
