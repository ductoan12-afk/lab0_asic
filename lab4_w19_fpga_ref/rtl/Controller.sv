`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 02:21:46 PM
// Design Name: Nguyen Duc Toan
// Module Name: Controller
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


module Controller(
    // Input t?ng Decode (ID)
    input logic [6:0] opcode,
    input logic [2:0] funct3D, // instrD[14:12]
    input logic funct7,        // instrD[30]
    
    // Input t? Pipeline Register truy?n sang t?ng Execute (EX)
    input logic branchE,
    input logic jumpE,
    input logic [2:0] funct3E,
    input logic ZeroE,
    input logic LessE,
    
    // Output cho t?ng Decode (ID)
    output logic regwriteD,
    output logic [2:0] ImmSrcD,
    output logic alu_srcD,
    output logic memwriteD,
    output logic [1:0] result_srcD,
    output logic branchD,
    output logic jumpD,
    output logic [3:0] ALUcontrolD,
    
    // Output cho t?ng Execute (EX)
    output logic PCSrcE
    );
    
    logic [1:0] alu_opD;
    logic take_branchE;
    
    // 1. Khoi Main Decoder (Giai ma tai tang Decode)
    Main_decoder main_de( 
        .opcode(opcode),
        .reg_write(regwriteD),
        .ImmSrc(ImmSrcD),
        .alu_src(alu_srcD),
        .mem_write(memwriteD),
        .result_src(result_srcD),
        .branch(branchD),
        .jump(jumpD),
        .alu_op(alu_opD)  
    );

    // 2. Khoi ALU Decoder (Giai ma tai tang Decode)
    Alu_decoder ald_de(
        .opb5(opcode[5]),
        .funct3(funct3D),
        .funct7(funct7),
        .alu_op(alu_opD),
        .ALUcontrol(ALUcontrolD) 
    );
    
    // 3. Khoi Re Nhanh (Thuc hien HOAN TOAN tai tang EX)
    always_comb begin
        case(funct3E)
            3'b000 : take_branchE = ZeroE;       // BEQ
            3'b001 : take_branchE = ~ZeroE;      // BNE
            3'b100 : take_branchE = LessE;       // BLT
            3'b101 : take_branchE = ~LessE;      // BGE
            3'b110 : take_branchE = LessE;       // BLTU
            3'b111 : take_branchE = ~LessE;      // BGEU
            default : take_branchE = 1'b0;
        endcase
    end
    
    // Tính PCSrcE t?i t?ng EX b?ng các tín hi?u ?ã ??ng b? qua ID/EX Pipeline Register
    assign PCSrcE = (branchE & take_branchE) | jumpE;

endmodule
