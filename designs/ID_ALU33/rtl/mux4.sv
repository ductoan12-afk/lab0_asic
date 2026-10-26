`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2026 11:32:03 AM
// Design Name: Nguyen Duc Toan
// Module Name: mux4
// Project Name: CPU_C
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


module mux4 #(
    parameter WIDTH = 32
    )(
        input logic [WIDTH-1:0] d0,
        input logic [WIDTH-1:0] d1,
        input logic [WIDTH-1:0] d2,
        input logic [WIDTH-1:0] d3,
        input logic [1:0] sel,
        output logic [WIDTH-1:0] y
    );
    
    always_comb begin
        case(sel)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            2'b11: y = d3;
        endcase
    end
endmodule
