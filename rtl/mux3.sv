`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2026 04:00:09 PM
// Design Name: Nguyen Duc Toan
// Module Name: mux3
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


module mux3 #(
    parameter WIDTH = 32
)(
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    input logic [WIDTH-1:0] d2,
    input logic [1:0] sel,
    output logic [WIDTH-1:0] y
    );
    
    always_comb begin
        case(sel)
            2'b00 : y = d0;
            2'b01 : y = d1;
            2'b10 : y = d2;       
            default : y = d0;
        endcase
    end
endmodule
