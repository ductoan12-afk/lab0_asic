`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/01/2026 09:43:36 PM
// Design Name: Nguyen Duc Toan
// Module Name: branch_compare1
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
module branch_compare1(
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [2:0] funct3,
    input logic BranchE,
    output logic BranchTakenE
);
    always_comb begin
        BranchTakenE = 1'b0;

        if(BranchE) begin
            case(funct3)
                3'b000 : BranchTakenE = (SrcA == SrcB); //BEQ
                3'b001 : BranchTakenE = (SrcA != SrcB); //BNE
                3'b100 : BranchTakenE = ($signed(SrcA) < $signed(SrcB)); //BLT
                3'b101 : BranchTakenE = ($signed(SrcA) >= $signed(SrcB)); //BGE
                3'b110 : BranchTakenE = (SrcA < SrcB); //BLTU
                3'b111 : BranchTakenE = (SrcA >= SrcB); //BGEU
                default : BranchTakenE = 1'b0;
            endcase
        end
     end
endmodule
