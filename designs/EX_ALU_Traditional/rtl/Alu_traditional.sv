`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09/12/2026 10:09:42 AM
// Design Name: Nguyen Duc Toan
// Module Name: alu
// Project Name: RV32I_EX_Traditional
// Target Devices:
// Tool Versions:
// Description:
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module Alu_traditional(
    input  logic [31:0] SrcA,
    input  logic [31:0] SrcB,
    input  logic [3:0]  ALUcontrol,
    output logic [31:0] ALUresult,
    output logic        Zero,
    output logic        Less
);

    logic       sub_en;
    logic       is_unsigned;
    logic [1:0] ALU_Control_Mux;

    // Control Decoder
    always_comb begin

        // Default
        sub_en          = 1'b0;
        is_unsigned     = 1'b0;
        ALU_Control_Mux = 2'b10;

        case (ALUcontrol)

            // ADD
            4'b0000: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b01;
            end

            // SUB
            4'b0001: begin
                sub_en          = 1'b1;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b01;
            end

            // AND
            4'b0010: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b10;
            end

            // OR
            4'b0011: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b10;
            end

            // XOR
            4'b0100: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b10;
            end

            // SLT
            4'b0101: begin
                sub_en          = 1'b1;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b00;
            end

            // SLL
            4'b0110: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b10;
            end

            // SRA
            4'b0111: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b10;
            end

            // SLTU
            4'b1000: begin
                sub_en          = 1'b1;
                is_unsigned     = 1'b1;
                ALU_Control_Mux = 2'b00;
            end

            // SRL
            4'b1001: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b10;
            end

            default: begin
                sub_en          = 1'b0;
                is_unsigned     = 1'b0;
                ALU_Control_Mux = 2'b10;
            end

        endcase

    end
    // Adder/Subtractor Unit
    logic [31:0] AddSubResult;

    always_comb begin

        if (sub_en)
            AddSubResult = SrcA + (~SrcB) + 32'd1;
        else
            AddSubResult = SrcA + SrcB;

    end
    // Comparator unit
    logic [31:0] CompareResult;

    always_comb begin

        if (is_unsigned)
            Less = (SrcA < SrcB);
        else
            Less = ($signed(SrcA) < $signed(SrcB));

        CompareResult = {31'b0, Less};

    end
    // Shilft and logic unit
    logic [31:0] ShiftLogicResult;

    always_comb begin

        case (ALUcontrol)

            // AND / ANDI
            4'b0010:
                ShiftLogicResult = SrcA & SrcB;

            // OR / ORI
            4'b0011:
                ShiftLogicResult = SrcA | SrcB;

            // XOR / XORI
            4'b0100:
                ShiftLogicResult = SrcA ^ SrcB;

            // SLL / SLLI
            4'b0110:
                ShiftLogicResult = SrcA << SrcB[4:0];

            // SRA / SRAI
            4'b0111:
                ShiftLogicResult = $signed(SrcA) >>> SrcB[4:0];

            // SRL / SRLI
            4'b1001:
                ShiftLogicResult = SrcA >> SrcB[4:0];

            default:
                ShiftLogicResult = 32'd0;

        endcase

    end
    // Mux 3:1
    always_comb begin

        case (ALU_Control_Mux)

            2'b00:
                ALUresult = CompareResult;

            2'b01:
                ALUresult = AddSubResult;

            2'b10:
                ALUresult = ShiftLogicResult;

            default:
                ALUresult = 32'd0;

        endcase

    end
    // Zero dectect.
    assign Zero = (AddSubResult == 32'd0);

endmodule