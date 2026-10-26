`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2026 03:44:57 PM
// Design Name: Nguyen Duc Toan
// Module Name: mux2
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


module mux2 #(
    parameter WIDTH = 32
)(
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    input logic sel,
    output logic [WIDTH-1:0] y
    );
    
    always_comb begin
        y = sel ? d1 : d0;
    end
endmodule
