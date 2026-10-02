`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2026 10:09:42 AM
// Design Name: Nguyen Duc Toan
// Module Name: alu
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


module alu(
    input logic [31:0] SrcA,
    input logic [31:0] SrcB,
    input logic [3:0] ALUcontrol,
    output logic [31:0] ALUresult,
    output logic Zero,
    output logic Less        // C? Less 1-bit m?i trích xu?t t? Sum_33[32
    );
    
    
    // Tang 1: Bo Control Decoder
    logic sub_en;
    logic is_unsigned;
    
    always_comb begin
        case (ALUcontrol)
            4'b0001: begin sub_en = 1'b1; is_unsigned = 1'b0; end // SUB, BEQ, BNE, BLT, BGE
            4'b0101: begin sub_en = 1'b1; is_unsigned = 1'b0; end // SLT
            4'b1000: begin sub_en = 1'b1; is_unsigned = 1'b1; end // SLTU, BLTU, BGEU
            default: begin sub_en = 1'b0; is_unsigned = 1'b0; end // ADD, Logic, Shift
        endcase
    end
    
    // Bo mo rong bit 32 -> 33 bits
    logic [32:0] A_ext;
    logic [32:0] B_ext_raw;
    logic [32:0] B_ext;
    assign A_ext      = is_unsigned ? {1'b0, SrcA} : {SrcA[31], SrcA};  // mo rong len 32bits
    assign B_ext_raw = is_unsigned ? {1'b0, SrcB} : {SrcB[31], SrcB};
    
    // Dao B
    assign B_ext = sub_en ? ~B_ext_raw : B_ext_raw;  // Neu su dung sub thi dao B, k thi thoi
    
    // Tang 2: Adder 33 bits
    logic [32:0] Sum_33;
    assign Sum_33 = A_ext + B_ext + sub_en;
    
    // gan co less : dung cho lenh branch
    assign Less = is_unsigned ? (SrcA < SrcB) : ($signed(SrcA) < $signed(SrcB));
    
    assign Zero = (Sum_33[31:0] == 32'd0) ? 1'b1 : 1'b0;
    // Khoi dich bit va logic unit
    logic signed [31:0] shift_logic_result;
    always_comb begin
        case(ALUcontrol)
            4'b0010 : shift_logic_result = SrcA & SrcB; // and,andi
            4'b0011 : shift_logic_result = SrcA | SrcB; // or,ori
            4'b0100 : shift_logic_result = SrcA ^ SrcB; // xor,xori 
            4'b0110 : shift_logic_result = SrcA << SrcB[4:0]; // sll,slli
            4'b0111 : shift_logic_result = $signed(SrcA) >>> SrcB[4:0]; // sra,srai   dich toi da 32 bits
            4'b1001 : shift_logic_result = SrcA >> SrcB[4:0]; // srl,srli
            
            default : shift_logic_result = 32'd0;
        endcase
    end
    // Khoi MUX 3:1 chon ALUresult
    always_comb begin
        case (ALUcontrol)
            4'b0000, 4'b0001: ALUresult = Sum_33[31:0];        // Kênh 00: ADD / SUB
            4'b0101, 4'b1000: ALUresult = {31'b0, Less}; // Kênh 01: SLT / SLTU
            4'b0010, 4'b0011, 4'b0100, 
            4'b0110, 4'b0111, 4'b1001: ALUresult = shift_logic_result; // Shift & Logic
            default:          ALUresult = 32'd0;  
        endcase
    end

endmodule
