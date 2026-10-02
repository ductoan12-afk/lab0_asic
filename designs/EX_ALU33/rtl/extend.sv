`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2026 04:35:15 PM
// Design Name: Nguyen Duc Toan
// Module Name: extend
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


module extend (
    input logic [31:7] Instr,
    input logic [2:0] ImmSrc,
    output logic [31:0] ImmExt        
    );
    always_comb begin
        case (ImmSrc)    
            // I-type: bit goc la instr[31:20] 12 bit -> 32 bit
            3'b000 : ImmExt = {{20{Instr[31]}},Instr[31:20]};
            
            // S-type: bit goc la instr[31:25] va instr[11:7] 12 bit -> 32 bit
            3'b001 : ImmExt = {{20{Instr[31]}},Instr[31:25],Instr[11:7]};
            
            // B-type: bit goc lung tung, chu y
            3'b010 : ImmExt = {{20{Instr[31]}},Instr[7],Instr[30:25],Instr[11:8],1'b0};
            
            // J-type: bit goc lung tung, chu y bit goc 20 bit -> 32 bit
            3'b011 : ImmExt = {{12{Instr[31]}},Instr[19:12],Instr[20],Instr[30:21],1'b0};
            
            // U-type: bit goc instr[31:12] o trong so cao nhat -> 32 bit
            3'b100 : ImmExt = {Instr[31:12],12'b0};
            
            default : ImmExt = 32'b0;
        
        endcase
    end
endmodule
