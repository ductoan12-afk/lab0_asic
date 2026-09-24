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
    input logic [31:0] a,
    output logic [31:0] rd
);

    logic [31:0] ROM[16383:0];
    string hex_file;

    initial begin
        if (!$value$plusargs("HEX=%s", hex_file)) begin
            hex_file = "test_alu.hex";
        end

        $display("[IMEM] Loading HEX: %s", hex_file);
        $readmemh(hex_file, ROM);
    end

    assign rd = ROM[a[31:2]];

endmodule



