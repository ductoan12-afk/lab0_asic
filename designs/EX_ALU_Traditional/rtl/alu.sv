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
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module alu(
    input  logic [31:0] SrcA,
    input  logic [31:0] SrcB,
    input  logic [3:0] ALUcontrol,
    output logic [31:0] ALUresult,
    output logic Zero,
    output logic Less
);

    //========================================================
    // Control cho phep SUB / SLT / SLTU
    //========================================================
    logic sub_en;
    logic is_unsigned;
    logic [1:0] ALU_Control_Mux;

    always_comb begin
        case (ALUcontrol)
            4'b0001: begin
                sub_en = 1'b1;
                is_unsigned = 1'b0;
            end

            4'b0101: begin
                sub_en = 1'b1;
                is_unsigned = 1'b0;
            end

            4'b1000: begin
                sub_en = 1'b1;
                is_unsigned = 1'b1;
            end

            default: begin
                sub_en = 1'b0;
                is_unsigned = 1'b0;
            end
        endcase
    end

    //========================================================
    // Mo rong 32 bit -> 33 bit
    //========================================================
    logic [32:0] A_ext;
    logic [32:0] B_ext_raw;
    logic [32:0] B_ext;

    assign A_ext = is_unsigned ?
                   {1'b0, SrcA} :
                   {SrcA[31], SrcA};

    assign B_ext_raw = is_unsigned ?
                       {1'b0, SrcB} :
                       {SrcB[31], SrcB};

    // Dao B khi thuc hien phep tru
    assign B_ext = sub_en ? ~B_ext_raw : B_ext_raw;

    //========================================================
    // Adder 33 bit
    //========================================================
    logic [32:0] Sum_33;

    assign Sum_33 = A_ext + B_ext + sub_en;

    //========================================================
    // So sanh SLT / SLTU
    //========================================================
    assign Less = is_unsigned ?
                  (SrcA < SrcB) :
                  ($signed(SrcA) < $signed(SrcB));

    //========================================================
    // Logic va Shift
    //========================================================
    logic signed [31:0] shift_logic_result;

    always_comb begin
        case (ALUcontrol)

            4'b0010:
                shift_logic_result = SrcA & SrcB;       // AND / ANDI

            4'b0011:
                shift_logic_result = SrcA | SrcB;       // OR / ORI

            4'b0100:
                shift_logic_result = SrcA ^ SrcB;       // XOR / XORI

            4'b0110:
                shift_logic_result = SrcA << SrcB[4:0]; // SLL / SLLI

            4'b0111:
                shift_logic_result = $signed(SrcA) >>> SrcB[4:0]; // SRA / SRAI

            4'b1001:
                shift_logic_result = SrcA >> SrcB[4:0]; // SRL / SRLI

            default:
                shift_logic_result = 32'd0;

        endcase
    end

    //========================================================
    // Chon ket qua ALU
    //========================================================
    always_comb begin
        case (ALUcontrol)

            4'b0000,
            4'b0001:
                ALUresult = Sum_33[31:0];               // ADD / SUB

            4'b0101,
            4'b1000:
                ALUresult = {31'b0, Less};              // SLT / SLTU

            4'b0010,
            4'b0011,
            4'b0100,
            4'b0110,
            4'b0111,
            4'b1001:
                ALUresult = shift_logic_result;         // Logic / Shift

            default:
                ALUresult = 32'd0;

        endcase
    end

    //========================================================
    // Zero flag
    // Zero phai duoc tao tu ALUresult
    //========================================================
    assign Zero = (ALUresult == 32'd0);

endmodule
