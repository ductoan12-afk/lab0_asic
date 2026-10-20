`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Design Name: Nguyen Duc Toan
// Module Name: alu
// Project Name: RV32I
//
// Description:
// Unified RV32I ALU.
//
// A single shared 33-bit adder is used for:
//   ADD, SUB, SLT, SLTU
//   and branch comparisons:
//   BEQ, BNE, BLT, BGE, BLTU, BGEU
//
//////////////////////////////////////////////////////////////////////////////////

module alu(
    input  logic [31:0] SrcA,
    input  logic [31:0] SrcB,
    input  logic [3:0]  ALUcontrol,
    output logic [31:0] ALUresult,
    output logic        Zero,
    output logic        Less
);

    //========================================================
    // Control
    //
    // 0000 : ADD
    // 0001 : SUB / BEQ / BNE
    // 0101 : SLT / BLT / BGE
    // 1000 : SLTU / BLTU / BGEU
    //========================================================

    logic sub_en;
    logic is_unsigned;

    always_comb begin
        case (ALUcontrol)

            // Signed subtraction / signed comparison
            4'b0001,
            4'b0101: begin
                sub_en      = 1'b1;
                is_unsigned = 1'b0;
            end

            // Unsigned subtraction / unsigned comparison
            4'b1000: begin
                sub_en      = 1'b1;
                is_unsigned = 1'b1;
            end

            default: begin
                sub_en      = 1'b0;
                is_unsigned = 1'b0;
            end

        endcase
    end


    //========================================================
    // Extend operands to 33 bits
    //
    // Signed operation:
    //   sign extension
    //
    // Unsigned operation:
    //   zero extension
    //========================================================

    logic [32:0] A_ext;
    logic [32:0] B_ext_raw;
    logic [32:0] B_ext;

    assign A_ext =
        is_unsigned ?
        {1'b0, SrcA} :
        {SrcA[31], SrcA};

    assign B_ext_raw =
        is_unsigned ?
        {1'b0, SrcB} :
        {SrcB[31], SrcB};

    // For subtraction:
    //   A - B = A + (~B) + 1
    assign B_ext =
    sub_en ?
    (is_unsigned ? {1'b0, ~SrcB}
                 : ~B_ext_raw) :
    B_ext_raw;

    //========================================================
    // ONE SHARED 33-BIT ADDER
    //========================================================

    logic [32:0] Sum_33;

    assign Sum_33 = A_ext + B_ext + sub_en;


    //========================================================
    // Signed overflow
    //
    // Overflow for:
    //   A - B
    //
    // = (signA != signB) &&
    //   (signResult != signA)
    //========================================================

    logic Overflow;

    assign Overflow =
        (SrcA[31] != SrcB[31]) &&
        (Sum_33[31] != SrcA[31]);


    //========================================================
    // LESS derived from the SAME 33-bit ADDER
    //
    // Signed:
    //   SLT = Sign(Result) XOR Overflow
    //
    // Unsigned:
    //   A < B when subtraction produces a borrow.
    //   For A + ~B + 1:
    //     Carry-out = 0 -> borrow -> A < B
    //
    // Therefore:
    //   unsigned_less = ~CarryOut
    //========================================================

    logic Less_signed;
    logic Less_unsigned;

    assign Less_signed =
        Sum_33[31] ^ Overflow;

    assign Less_unsigned =
        ~Sum_33[32];

    assign Less =
        is_unsigned ?
        Less_unsigned :
        Less_signed;


    //========================================================
    // Logic and Shift operations
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
                shift_logic_result =
                    SrcA << SrcB[4:0];                  // SLL / SLLI

            4'b0111:
                shift_logic_result =
                    $signed(SrcA) >>> SrcB[4:0];        // SRA / SRAI

            4'b1001:
                shift_logic_result =
                    SrcA >> SrcB[4:0];                  // SRL / SRLI

            default:
                shift_logic_result = 32'd0;

        endcase
    end


    //========================================================
    // ALU result
    //========================================================

    always_comb begin
        case (ALUcontrol)

            // ADD / SUB
            4'b0000,
            4'b0001:
                ALUresult = Sum_33[31:0];

            // SLT / SLTU
            //
            // Less comes from the shared 33-bit adder.
            4'b0101,
            4'b1000:
                ALUresult = {31'b0, Less};

            // Logic / Shift
            4'b0010,
            4'b0011,
            4'b0100,
            4'b0110,
            4'b0111,
            4'b1001:
                ALUresult = shift_logic_result;

            default:
                ALUresult = 32'd0;

        endcase
    end


    //========================================================
    // Zero flag
    //
    // BEQ/BNE use ALUcontrol = SUB,
    // so Zero represents:
    //
    //   SrcA - SrcB == 0
    //========================================================

    assign Zero = (ALUresult == 32'd0);

endmodule
