`timescale 1ns / 1ps

// ============================================================
// EX_ALU33 - Combined RTL
// Current Instruction_memory + 16K backup variant
// ============================================================

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2026 04:20:18 PM
// Design Name: Nguyen Duc Toan
// Module Name: adder
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


module adder #(
    parameter WIDTH = 32 // dung chung 32bit
)(
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    output logic [WIDTH-1:0] y
    );
    
    always_comb begin
        y = d0 + d1;
    
    end
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 10:43:39 AM
// Design Name: Nguyen Duc Toan
// Module Name: Alu_decoder
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


module Alu_decoder(
    input logic opb5, // instr[5] ?? phân bi?t I-R format
    input logic [2:0] funct3, // instr[14:12]
    input logic funct7, // instr[30] , ch? c?n bit 30 ?? phân bi?t funct7
    input logic [1:0] alu_op, // tín hi?u t? main decoder
    output logic [3:0] ALUcontrol // tín hi?u t? alu
    );
    
    always_comb begin
        case(alu_op)
            // Kh?i x? lí cho l?nh LOAD/STORE
            2'b00 : ALUcontrol = 4'b0000; // s? d?ng l?nh add ?? tính EA 
            
            // KH?i x? lí cho các l?nh branch            
            2'b01: begin
                case(funct3)
                    3'b000,3'b001 : ALUcontrol = 4'b0001; // BEQ,BNE  dùng phép sub, Zero ?? phân bi?t
                    3'b100,3'b101 : ALUcontrol = 4'b0101; // BLT,BGE   dùng SLT k?t h?p thêm ph?n taken_branch ? file t?ng control ?? phân bi?t
                    3'b110,3'b111 : ALUcontrol = 4'b1000; // BLTU,BGEU  dùng SLTU
                    default : ALUcontrol = 4'b0001;
                endcase     
            end
            
            //Kh?i ALU R I
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (opb5 && funct7) 
                            ALUcontrol = 4'b0001; // SUB
                        else                 
                            ALUcontrol = 4'b0000; // ADD / ADDI
                    end
                    3'b001:  ALUcontrol = 4'b0110; // SLL / SLLI
                    3'b010:  ALUcontrol = 4'b0101; // SLT / SLTI
                    3'b011:  ALUcontrol = 4'b1000; // SLTU / SLTUI
                    3'b100:  ALUcontrol = 4'b0100; // XOR / XORI
                    3'b101: begin
                        if (funct7)
                            ALUcontrol = 4'b0111; // SRA / SRAI
                        else
                            ALUcontrol = 4'b1001; // SRL / SRLI
                    end
                    3'b110:  ALUcontrol = 4'b0011; // OR / ORI
                    3'b111:  ALUcontrol = 4'b0010; // AND / ANDI
                    default: ALUcontrol = 4'b0000;
                endcase
            end            
        default: ALUcontrol = 4'b0000;
        endcase

    end
endmodule


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
            3'b100,
		3'b101 : ImmExt = {Instr[31:12],12'b0};
            
            default : ImmExt = 32'b0;
        
        endcase
    end
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2026 03:44:57 PM
// Design Name: Nguyen Duc Toan
// Module Name: mux2
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


module mux2 #(
    parameter WIDTH = 32
)(
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    input logic sel,
    output logic [WIDTH-1:0] y
    );
    
    always_comb begin
        y = sel ? d1 : d0;
    end
endmodule


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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 09:39:00 AM
// Design Name: Nguyen Duc Toan
// Module Name: Main_decoder
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

// Kh?i gi?i mã opcode ?? xác ??nh format và ?i?u khi?n các dây control
module Main_decoder(
    input logic [6:0] opcode, 
    output logic reg_write, // cho phép ghi l?i vào thanh ghi
    output logic [2:0] ImmSrc, // do 5 tr??ng h?p immediate m? rông cua 5 format
    output logic alu_src, // ?i?u khi?n mux2:1 ?? ch?n rs2
    output logic mem_write, // cho phép ghi vào RAM
    output logic [1:0] result_src, // ch?n ki?u d? li?u ghi l?i vào thanh ghi
    output logic branch, // cho phép r? nhánh
    output logic jump, // cho phép nh?y không ?i?u ki?n
    output logic [1:0] alu_op // mã ch? thi ? alu_decode
    );
    
    logic [11:0] controls; // tín hi?u 12 bit
    // ép v? 1 controls ?i?u khi?n 12 bit output
    assign {reg_write,ImmSrc,alu_src,mem_write,result_src,branch,jump,alu_op} = controls;
    
    always_comb begin
        case(opcode)
            // R_type   , x dont care dù tr??ng h?p 0 hay 1 thì không ?nh h??ng 
            7'b0110011 : controls = 12'b1_000_0_0_00_0_0_10;
            // I_type
            7'b0010011 : controls = 12'b1_000_1_0_00_0_0_10;
            // Load (lw)
            7'b0000011 : controls = 12'b1_000_1_0_01_0_0_00;

            // Store (sw)
            7'b0100011 : controls = 12'b0_001_1_1_00_0_0_00;

            // Branch 
            7'b1100011 : controls = 12'b0_010_0_0_00_1_0_01;

            // JAL (Jump)
            7'b1101111 : controls = 12'b1_011_0_0_10_0_1_00;
	    7'b1100111 : controls = 12'b1_000_1_0_10_0_1_00; // JALR
            // U-type 
            7'b0110111 : controls = 12'b1_100_1_0_00_0_0_00;
		7'b0010111 : controls = 12'b1_101_1_0_00_0_0_00; // AUIPC
            // Default: NOP
            default :    controls = 12'b0_000_0_0_00_0_0_00;        
        endcase
    end
endmodule



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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 11:24:02 AM
// Design Name: Nguyen Duc Toan
// Module Name: Hazard_Unit
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


module Hazard_Unit( 
    // Input dau vao (kiem tra)
    input logic [4:0] Rs1D,Rs2D,
    input logic [4:0] Rs1E,Rs2E,
    input logic [4:0] RdE,RdM,RdW,
    input logic regwriteM,regwriteW,
    input logic [1:0] result_srcE,
    input logic PCsrcE,
    
    // Output dau ra (thuc thi)
    output logic StallF,StallD,
    output logic FlushD,FlushE,
    output logic [1:0] ForwardA,ForwardB
    );
    logic lwstall; // stall o lenh lw
    // Loi Forwarding ALU
    // uu tien MEM stage
    always_comb begin  // input1 vao ALU
        if(regwriteM && RdM != 5'd0 && (RdM == Rs1E)) begin
            ForwardA = 2'b10;
        end
        else if(regwriteW && RdW != 5'd0 && (RdW == Rs1E)) begin
            ForwardA = 2'b01;
        end
        else begin
            ForwardA = 2'b00;
        end
    end
    
    // input2 vao ALU
    always_comb begin 
        if(regwriteM && RdM != 5'd0 && (RdM == Rs2E)) begin
            ForwardB = 2'b10;
        end
        else if(regwriteW && RdW != 5'd0 && (RdW == Rs2E)) begin
            ForwardB = 2'b01;
        end
        else begin
            ForwardB = 2'b00;
        end
    end
    // xu li loi load-use hazard
// Phép so sánh === s? tr? v? 0 (False) n?u result_srcE[0] là 'x', không b? lan truy?n 'x'
    assign lwstall = (result_srcE[0] === 1'b1) && (RdE != 5'd0) && ((RdE == Rs1D) || (RdE == Rs2D));
    assign StallD = lwstall;
    assign StallF = lwstall;
    
    // xu li loi control hazard
    assign FlushD = PCsrcE;
    assign FlushE = lwstall || PCsrcE;
    
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2026 05:00:58 PM
// Design Name: Nguyen Duc Toan
// Module Name: reg_if_id
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


module reg_if_id(
    input logic clk, reset,
    input logic EN,
    input logic CLR,
    
    // Input vao tang IF
    input logic [31:0] InstrF,
    input logic [31:0] PCF,
    input logic [31:0] PCPlus4F,
    
    // Output ra tang ID
    output logic [31:0] InstrD,
    output logic [31:0] PCD,
    output logic [31:0] PCPlus4D
    );
    
    always_ff @(posedge clk or posedge reset) begin
        // Reset tin hieu 
        if(reset) begin
            InstrD <= 32'd0;
            PCD <= 32'd0;
            PCPlus4D <= 32'd0;
        end
        
        // Flush (xoa du lieu tang IF)
        else if(CLR) begin
            InstrD <= 32'd0;
            PCD <= 32'd0;
            PCPlus4D <= 32'd0;
        end
        
        else if(EN) begin
            InstrD <= InstrF;
            PCD <= PCF;
            PCPlus4D <= PCPlus4F;
        end
        // neu EN = 0 thi output van giu nguyen 
    end
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/17/2026 05:24:43 PM
// Design Name: Nguyen Duc Toan
// Module Name: reg_id_ex
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


module reg_id_ex(
    input logic clk,reset,
    input logic CLR,
    // Tin hieu dieu khien (Control Unit)
    input logic regwriteD,
    input logic [1:0] result_srcD,
    input logic mem_writeD,
    input logic jumpD,
    input logic branchD,
    input logic [3:0] ALUcontrolD,
    input logic alu_srcD,
    input logic [2:0] ImmSrcD,
    
    // Tin hieu du lieu, dia chi (dau vao ID/EX)
    input logic [31:0] rd1D,rd2D,
    input logic [31:0] PCD,
    input logic [4:0] Rs1D,Rs2D,
    input logic [4:0] RdD,
    input logic [31:0] ImmExtD,
    input logic [31:0] PCPlus4D,
    input logic [2:0] funct3D,
    
    // Tin hieu dau ra (ID/EX)
    output logic regwriteE,
    output logic [1:0] result_srcE,
    output logic mem_writeE,
    output logic jumpE,
    output logic branchE,
    output logic [3:0] ALUcontrolE,
    output logic alu_srcE,
    output logic [2:0] ImmSrcE,
    output logic [31:0] rd1E,rd2E,
    output logic [31:0] PCE,
    output logic [4:0] Rs1E,Rs2E,
    output logic [4:0] RdE,
    output logic [31:0] ImmExtE,
    output logic [31:0] PCPlus4E,
    output logic [2:0] funct3E
    );
    always_ff @(posedge clk or posedge reset) begin
        // Reset lai tin hieu 
        if(reset) begin
            regwriteE <= 1'd0;
            result_srcE <= 2'd0;
            mem_writeE <= 1'd0;
            jumpE <= 1'd0;
            branchE <= 1'd0;
            ALUcontrolE <= 4'd0;
            alu_srcE <= 1'd0;
            ImmSrcE <= 3'b000;
            rd1E <= 32'd0;
            rd2E <= 32'd0;
            PCE <= 32'd0;
            Rs1E <= 5'd0;
            Rs2E <= 5'd0;
            RdE <= 5'd0;
            ImmExtE <= 32'd0;
            PCPlus4E <= 32'd0;
            funct3E     <= 3'b0;
        end
        // Flush (xoa cac du lieu o tang ID)
        else if(CLR) begin
            regwriteE <= 1'd0;
            result_srcE <= 2'd0;
            mem_writeE <= 1'd0;
            jumpE <= 1'd0;
            branchE <= 1'd0;
            ALUcontrolE <= 4'd0;
            alu_srcE <= 1'd0;
            ImmSrcE <= 3'b000;
            rd1E <= 32'd0;
            rd2E <= 32'd0;
            PCE <= 32'd0;
            Rs1E <= 5'd0;
            Rs2E <= 5'd0;
            RdE <= 5'd0;
            ImmExtE <= 32'd0;
            PCPlus4E <= 32'd0; 
            funct3E     <= 3'b0;   
        end
        else begin
            regwriteE <= regwriteD;
            result_srcE <= result_srcD;
            mem_writeE <= mem_writeD;
            jumpE <= jumpD;
            branchE <= branchD;
            ALUcontrolE <= ALUcontrolD;
            alu_srcE <= alu_srcD;
            ImmSrcE <= ImmSrcD;
            rd1E <= rd1D;
            rd2E <= rd2D;
            PCE <= PCD;
            Rs1E <= Rs1D;
            Rs2E <= Rs2D;
            RdE <= RdD;
            ImmExtE <= ImmExtD;
            PCPlus4E <= PCPlus4D;  
            funct3E     <= funct3D;          

        end    
    end
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 09:29:22 AM
// Design Name: Nguyen Duc Toan
// Module Name: reg_ex_mem
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


module reg_ex_mem(
    input logic clk,reset,

    // input dau vao tang EX/MEM
    input logic regwriteE,
    input logic [1:0] result_srcE,
    input logic mem_writeE,
    input logic [31:0] ALUresultE,
    input logic [31:0] WriteDataE,
    input logic [31:0] PCPlus4E,
    input logic [4:0] RdE,
	input logic [2:0] funct3E,    
    // output cua tang EX/MEM
    output logic regwriteM,
    output logic [1:0] result_srcM,
    output logic mem_writeM,
    output logic [31:0] ALUresultM,
    output logic [31:0] WriteDataM,
    output logic [31:0] PCPlus4M,
    output logic [4:0] RdM,
    output logic [2:0] funct3M
    );
    
    always_ff @(posedge clk or posedge reset) begin
        // Reset tin hieu
        if(reset) begin
            regwriteM <= 1'd0;
            result_srcM <= 2'd0;
            mem_writeM <= 1'd0;
            ALUresultM <= 32'd0;
            WriteDataM <= 32'd0;
            PCPlus4M <= 32'd0;
            RdM <= 5'd0;
 	    funct3M <= 3'b000;       
        end
        else begin
            regwriteM <= regwriteE;
            result_srcM <= result_srcE;
            mem_writeM <= mem_writeE;
            ALUresultM <= ALUresultE;
            WriteDataM <= WriteDataE;
            PCPlus4M <= PCPlus4E;
            RdM <= RdE;
	    funct3M <= funct3E;
        end
    end
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 09:47:48 AM
// Design Name: Nguyen Duc Toan
// Module Name: reg_mem_wb
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


module reg_mem_wb(
    input logic clk,reset,
    
    // Input dau vao MEM/WB
    input logic regwriteM,
    input logic [1:0] result_srcM,
    input logic [31:0] RAM_RD,
    input logic [31:0] ALUresultM,
    input logic [4:0] RdM,
    input logic [31:0] PCPlus4M,
    
    // Output dau ra MEM/WB
    output logic regwriteW,
    output logic [1:0] result_srcW,
    output logic [31:0] ALUresultW,
    output logic [31:0] ReadDataW,
    output logic [4:0] RdW,
    output logic [31:0] PCPlus4W
    );
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            regwriteW <= 1'd0;
            result_srcW <= 2'd0;
            ALUresultW <= 32'd0;
            ReadDataW <= 32'd0;
            RdW <= 5'd0;
            PCPlus4W <= 32'd0;
        end
        
        else begin
            regwriteW <= regwriteM;
            result_srcW <= result_srcM;
            ALUresultW <= ALUresultM;
            ReadDataW <= RAM_RD;
            RdW <= RdM;
            PCPlus4W <= PCPlus4M;
        end     
    end
    
endmodule



`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 08:55:14 AM
// Design Name: Nguyen Duc Toan
// Module Name: Register_file
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


module Register_file(
    input logic clk,
    input logic we3,  // RegWriteW(WB) -> Thanh ghi
    input logic [4:0] a1,a2,a3, // lan luot rs1,rs2,rd
    input logic [31:0] wd3, //ghi d? li?u vào rd
    output logic [31:0] rd1,rd2  // giá tr? ??c c?a rs1,rs2
    );
    
    logic [31:0] register [31:0]; // cau hinh 32 thanh ghi, moi thanh ghi 32 bit

    // KHOI TAO BAN DAU: Xóa toàn b? giá tr? X trong m?ng thanh ghi khi b?t ??u Simulation
    initial begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            register[i] = 32'd0;
        end
    end

    
    // khoi ghi lai tu wb -> thanh ghi
    always_ff @(negedge clk) begin // dung clk am de tranh loi Raw hazard
        if(we3 && (a3 != 5'd0)) begin
            register[a3] <= wd3;
        end
    end
    
// N?u ?ang ghi vào a3 trùng v?i a1/a2 ?ang ??c (và we3 = 1) -> Cho phép l?y th?ng wd3 ra ngay!
    assign rd1 = (a1 == 5'd0) ? 32'd0 : ((a1 == a3) && we3) ? wd3 : register[a1];
    assign rd2 = (a2 == 5'd0) ? 32'd0 : ((a2 == a3) && we3) ? wd3 : register[a2];
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/14/2026 07:42:27 AM
// Design Name: Nguyen Duc Toan
// Module Name: Data_memory
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
///////////////////////////////////////////////////////////////////////////

module Data_memory(
    input logic clk,
    input logic we,
    input logic [31:0] A,
    input logic [31:0] wd,
    input logic [2:0] funct3,
    output logic [31:0] RD
);

    logic [31:0] RAM[16383:0];

    integer i;
    string hex_file;

    initial begin
        for (i = 0; i < 16384; i = i + 1)
            RAM[i] = 32'd0;

        if (!$value$plusargs("HEX=%s", hex_file))
            hex_file = "test_alu.hex";

        $display("[DMEM] Loading HEX: %s", hex_file);
        $readmemh(hex_file, RAM);
	$display("[DMEM CHECK] RAM[3072] = %08h", RAM[3072]);
    end

    // =========================
    // READ
    // =========================
    always_comb begin
        case (funct3)

            // LB
            3'b000: begin
                case (A[1:0])
                    2'b00: RD = {{24{RAM[A[15:2]][7]}},  RAM[A[15:2]][7:0]};
                    2'b01: RD = {{24{RAM[A[15:2]][15]}}, RAM[A[15:2]][15:8]};
                    2'b10: RD = {{24{RAM[A[15:2]][23]}}, RAM[A[15:2]][23:16]};
                    2'b11: RD = {{24{RAM[A[15:2]][31]}}, RAM[A[15:2]][31:24]};
                endcase
            end

            // LH
            3'b001: begin
                if (A[1] == 1'b0)
                    RD = {{16{RAM[A[15:2]][15]}}, RAM[A[15:2]][15:0]};
                else
                    RD = {{16{RAM[A[15:2]][31]}}, RAM[A[15:2]][31:16]};
            end

            // LW
            3'b010: begin
                RD = RAM[A[15:2]];
            end

            // LBU
            3'b100: begin
                case (A[1:0])
                    2'b00: RD = {24'd0, RAM[A[15:2]][7:0]};
                    2'b01: RD = {24'd0, RAM[A[15:2]][15:8]};
                    2'b10: RD = {24'd0, RAM[A[15:2]][23:16]};
                    2'b11: RD = {24'd0, RAM[A[15:2]][31:24]};
                endcase
            end

            // LHU
            3'b101: begin
                if (A[1] == 1'b0)
                    RD = {16'd0, RAM[A[15:2]][15:0]};
                else
                    RD = {16'd0, RAM[A[15:2]][31:16]};
            end

            default: RD = RAM[A[15:2]];

        endcase
    end

    // =========================
    // WRITE
    // =========================
    always_ff @(posedge clk) begin
        if (we) begin

            case (funct3)

                // SB
                3'b000: begin
                    case (A[1:0])
                        2'b00: RAM[A[15:2]][7:0]   <= wd[7:0];
                        2'b01: RAM[A[15:2]][15:8]  <= wd[7:0];
                        2'b10: RAM[A[15:2]][23:16] <= wd[7:0];
                        2'b11: RAM[A[15:2]][31:24] <= wd[7:0];
                    endcase
                end

                // SH
                3'b001: begin
                    if (A[1] == 1'b0)
                        RAM[A[15:2]][15:0] <= wd[15:0];
                    else
                        RAM[A[15:2]][31:16] <= wd[15:0];
                end

                // SW
                3'b010: begin
                    RAM[A[15:2]] <= wd;
                end

                default: begin
                    RAM[A[15:2]] <= wd;
                end

            endcase
        end
    end

endmodule



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

    localparam int IMEM_WORDS = 10100000;
    logic [31:0] ROM [0:IMEM_WORDS-1];
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


module Instruction_memory_16k(
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





`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 05:40:25 PM
// Design Name: Nguyen Duc Toan
// Module Name: riscv_pipelined
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

// DATAPATH
module riscv_pipelined(
    input logic clk,reset,
    input logic PCSrc,

    // Instruction Memory
    output logic [31:0] PCF,
    input logic [31:0] InstrF,
    
    // Data Memory
    output logic [31:0] ALUresultM,
    output logic [31:0] WriteDataM,
    output logic mem_writeM,
    input logic [31:0] ReadDataM,
    
    // Control Unit
    input logic regwriteD,
    input logic [1:0] result_srcD,
    input logic memwriteD,
    input logic jumpD,
    input logic branchD,
    input logic [3:0] ALUcontrolD,
    input logic alu_srcD,
    input logic [2:0] ImmSrcD,
    output logic [31:0] InstrD, // xuat lenh tu tang ID ra controller de giai ma
    output logic  ZeroE,
    output logic  LessE,
    output logic [31:0] ALUResultE,
    output logic branchE,
    output logic jumpE,
    output logic [2:0] funct3E,
    output logic [2:0] funct3M
    );
    
    // Khai bao cac duong day noi bo
    // Tang IF
    logic [31:0] PCNextF, PCPlus4F;
    
    // Tang ID
    logic [31:0] rd1D,rd2D;
    logic [31:0] PCD;
    logic [4:0] Rs1D,Rs2D,RdD;
    logic [31:0] ImmExtD;
    logic [31:0] PCPlus4D;
    
    // Tang EX
    logic regwriteE;
    logic [1:0] result_srcE;
    logic memwriteE;
    logic [3:0] ALUcontrolE;
    logic alu_srcE;
    logic [2:0] ImmSrcE;
    logic [31:0] rd1E,rd2E,PCE,ImmExtE,PCPlus4E;
    logic [31:0] WriteDataE,SrcA,SrcB,PCTargetE;
    logic [4:0] Rs1E,Rs2E,RdE;
    
    // Tang MEM
    logic regwriteM;
    logic [1:0] result_srcM;
    logic [4:0] RdM;
    logic [31:0] PCPlus4M;
    
    // Tang WB
    logic regwriteW;
    logic [31:0] ALUresultW,ReadDataW,PCPlus4W;
    logic [1:0] result_srcW;
    logic [31:0] ResultW;
    logic [4:0] RdW;
    
    // Hazard Unit
    logic StallF,StallD,FlushD,FlushE;
    logic [1:0] ForwardA,ForwardB;
    
    // Tang 1(IF)
    
    // MUX chon PCnext
    mux2 #(.WIDTH(32)) pc_next_mux (
        .d0(PCPlus4F),
        .d1(PCTargetE),
        .sel(PCSrc),
        .y(PCNextF)   
    );
    // Thanh ghi PC
    always_ff @(posedge clk or posedge reset) begin
        if(reset)
            PCF <= 32'd0;
        else if(!StallF) 
            PCF <= PCNextF;    
    end
    
    // Bo cong Adder -> PCPlus4F
    adder #(.WIDTH(32)) adderF(
        .d0(PCF),
        .d1(32'd4),
        .y(PCPlus4F) 
    );
    
    // PIPELINE 1(IF/ID)
    reg_if_id reg_id_if_pipeline(
        .clk(clk),.reset(reset),
        .EN(!StallD),.CLR(FlushD),
        .InstrF(InstrF),.PCF(PCF),
        .PCPlus4F(PCPlus4F),.InstrD(InstrD),
        .PCD(PCD),.PCPlus4D(PCPlus4D)
    );
    
    // Tang 2(ID)
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD = InstrD[11:7];
    
    Register_file Register_fileD(
        .clk(clk),.we3(regwriteW),
        .a1(Rs1D),.a2(Rs2D),
        .a3(RdW),.wd3(ResultW),
        .rd1(rd1D),.rd2(rd2D)
    );
    
    extend extendD(
        .Instr(InstrD[31:7]),
        .ImmSrc(ImmSrcD),
        .ImmExt(ImmExtD)
    );
    
    // PIPELINE 2(ID/EX)
    reg_id_ex reg_id_ex_pipeline(
        .clk(clk),.reset(reset),.CLR(FlushE),
        .regwriteD(regwriteD),.result_srcD(result_srcD),.mem_writeD(memwriteD),
        .jumpD(jumpD),.branchD(branchD),.ALUcontrolD(ALUcontrolD),
        .alu_srcD(alu_srcD),.ImmSrcD(ImmSrcD),.rd1D(rd1D),.rd2D(rd2D),.PCD(PCD),
        .Rs1D(Rs1D),.Rs2D(Rs2D),.RdD(RdD),.ImmExtD(ImmExtD),.PCPlus4D(PCPlus4D),
        .funct3D(InstrD[14:12]),
        
        .regwriteE(regwriteE),.result_srcE(result_srcE),.mem_writeE(memwriteE),
        .jumpE(jumpE),.branchE(branchE),.ALUcontrolE(ALUcontrolE),.alu_srcE(alu_srcE),.ImmSrcE(ImmSrcE),
        .rd1E(rd1E),.rd2E(rd2E),.PCE(PCE),.Rs1E(Rs1E),.Rs2E(Rs2E),
        .RdE(RdE),.ImmExtE(ImmExtE),.PCPlus4E(PCPlus4E),.funct3E(funct3E)
    );
    
    
    // Tang 3(EX)
    // MUX 3:1 A
    logic [31:0] SrcAForwarded;

    mux3 #(.WIDTH(32)) forwardA_mux(
        .d0(rd1E),
        .d1(ResultW),
        .d2(ALUresultM),
        .sel(ForwardA),
        .y(SrcAForwarded)
    );
    assign SrcA = (ImmSrcE == 3'b100) ? 32'd0 :
              (ImmSrcE == 3'b101) ? PCE :
              SrcAForwarded;
    
    // MUX 3:1 B
    mux3 #(.WIDTH(32)) forwardB_mux(
        .d0(rd2E),
        .d1(ResultW),
        .d2(ALUresultM),
        .sel(ForwardB),
        .y(WriteDataE)  
    );
    
    // MUX 3:1 chon SrcB
    mux2 #(.WIDTH(32)) MUX2_ALUsrcE(
        .d0(WriteDataE),
        .d1(ImmExtE),
        .sel(alu_srcE),
        .y(SrcB)
    );
    
    // ALU unit
    alu ALU_UNIT(
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUcontrol(ALUcontrolE),
        .ALUresult(ALUResultE),
        .Zero(ZeroE),
        .Less(LessE)
    );
    
    // Bo cong nhay ( adder immediate)
    always_comb begin
    if (jumpE && (ImmSrcE == 3'b000))
        PCTargetE = ALUResultE & 32'hFFFFFFFE; // JALR
    else
        PCTargetE = PCE + ImmExtE;             // JAL / branch
	end
    
    // PIPELINE 3(EX/MEM)
    reg_ex_mem reg_ex_mem_pipeline(
        .clk(clk),.reset(reset),.regwriteE(regwriteE),
        .result_srcE(result_srcE),.mem_writeE(memwriteE),
        .ALUresultE(ALUResultE),.WriteDataE(WriteDataE),
        .PCPlus4E(PCPlus4E),.RdE(RdE),.funct3E(funct3E),.regwriteM(regwriteM),
        .result_srcM(result_srcM),.mem_writeM(mem_writeM),
        .ALUresultM(ALUresultM),.WriteDataM(WriteDataM),
        .PCPlus4M(PCPlus4M),.RdM(RdM),.funct3M(funct3M)
    );
    
    // Tang 4(MEM)
    // PIPELINE 4(MEM/WB)
    reg_mem_wb reg_mem_wb_pipeline(
        .clk(clk),.reset(reset),.regwriteM(regwriteM),
        .result_srcM(result_srcM),.RAM_RD(ReadDataM),
        .ALUresultM(ALUresultM),.RdM(RdM),.PCPlus4M(PCPlus4M),
        .regwriteW(regwriteW),.result_srcW(result_srcW),.ALUresultW(ALUresultW),
        .ReadDataW(ReadDataW),.RdW(RdW),.PCPlus4W(PCPlus4W)
    );
    
    // Tang 5(WB)
    mux3 #(.WIDTH(32)) MUX3_ResultW(
        .d0(ALUresultW),
        .d1(ReadDataW),
        .d2(PCPlus4W),
        .sel(result_srcW),
        .y(ResultW)    
    );
    
    // Hazard Unit
    Hazard_Unit Hazard_Unit_datapath(
        .Rs1D(Rs1D),.Rs2D(Rs2D),.Rs1E(Rs1E),.Rs2E(Rs2E),
        .RdE(RdE),.RdM(RdM),.RdW(RdW),.regwriteM(regwriteM),
        .regwriteW(regwriteW),.result_srcE(result_srcE),
        .PCsrcE(PCSrc),.StallF(StallF),.StallD(StallD),
        .FlushD(FlushD),.FlushE(FlushE),.ForwardA(ForwardA),.ForwardB(ForwardB)
    );
endmodule




`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2026 08:43:05 AM
// Design Name: Nguyen Duc Toan
// Module Name: rv32i_top
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


module rv32i_top(
    input logic clk,
    input logic reset,
    
    // Cac tin hieu check/debug
    output logic [31:0] WriteDataM,
    output logic [31:0] ALUresultM,
    output logic mem_writeM
    );
    
    // Datapath - Instruction Memory
    logic [31:0] PCF;
    logic [31:0] InstrF;
    
    // Datapath - Data Memory
    logic [31:0] ReadDataM;
    
    // Datapath - Controller
    logic [31:0] InstrD;
    logic regwriteD;
    logic [1:0] result_srcD;
    logic memwriteD;
    logic jumpD;
    logic branchD;
    logic [3:0] ALUcontrolD;
    logic alu_srcD;
    logic [2:0] ImmSrcD;
    logic  ZeroE;
    logic LessE;
    logic [31:0] ALUResultE;
    logic PCSrcE;
    
    logic branchE;
    logic jumpE;
    logic [2:0] funct3E;
    logic [2:0] funct3M;    
    // Khoi tao Datapath
    riscv_pipelined Datapath(
        .clk(clk),.reset(reset),.PCSrc(PCSrcE),
        
        // Instruction memory
        .PCF(PCF),.InstrF(InstrF),
        
        // Data memory
        .ALUresultM(ALUresultM),.WriteDataM(WriteDataM),
        .mem_writeM(mem_writeM),.ReadDataM(ReadDataM),
        
        //Control unit
        .regwriteD(regwriteD),.result_srcD(result_srcD),
        .memwriteD(memwriteD),.jumpD(jumpD),.branchD(branchD),
        .ALUcontrolD(ALUcontrolD),.alu_srcD(alu_srcD),
        .ImmSrcD(ImmSrcD),.InstrD(InstrD),.ZeroE(ZeroE),.LessE(LessE),.ALUResultE(ALUResultE),
        .branchE(branchE),.jumpE(jumpE),.funct3E(funct3E),.funct3M(funct3M)
    );
    
    // Khoi tao Controller
    Controller Controller_unit(
        .opcode(InstrD[6:0]),
        .funct3D(InstrD[14:12]),
        .funct7(InstrD[30]),
        .branchE(branchE),
        .jumpE(jumpE),
        .funct3E(funct3E),
        .ZeroE(ZeroE),
        .LessE(LessE),
        .regwriteD(regwriteD),
        .ImmSrcD(ImmSrcD),
        .alu_srcD(alu_srcD),
        .memwriteD(memwriteD),
        .result_srcD(result_srcD),
        .branchD(branchD),
        .jumpD(jumpD),
        .ALUcontrolD(ALUcontrolD),
        .PCSrcE(PCSrcE)
    );
    
    // Khoi tao Instruction memory
    Instruction_memory Instruction_memory_unit(
        .a(PCF),.rd(InstrF)
    );
    
    // Khoi tao Data memory
    Data_memory Data_memory_unit(
        .clk(clk),.we(mem_writeM),
        .A(ALUresultM),.wd(WriteDataM),.funct3(funct3M),.RD(ReadDataM)
    );
    
endmodule


