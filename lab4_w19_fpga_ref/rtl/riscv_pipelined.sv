`timescale 1ns / 1ps

// ============================================================
// RV32I PIPELINED DATAPATH
// ============================================================
module riscv_pipelined (
    input  logic        clk,
    input  logic        reset,
    input  logic        PCSrc,

    // Instruction Memory
    output logic [31:0] PCF,
    output logic [31:0] PCNextF,
    input  logic [31:0] InstrF,

    // Stall output for synchronous instruction BRAM
    output logic        StallF,

    // Data Memory
    output logic [31:0] ALUresultM,
    output logic [31:0] WriteDataM,
    output logic        mem_writeM,
    input  logic [31:0] ReadDataM,

    // Control Unit
    input  logic        regwriteD,
    input  logic [1:0]  result_srcD,
    input  logic        memwriteD,
    input  logic        jumpD,
    input  logic        branchD,
    input  logic [3:0]  ALUcontrolD,
    input  logic        alu_srcD,
    input  logic [2:0]  ImmSrcD,

    output logic [31:0] InstrD,
    output logic        ZeroE,
    output logic        LessE,
    output logic [31:0] ALUResultE,
    output logic        branchE,
    output logic        jumpE,
    output logic [2:0]  funct3E,
    output logic [2:0]  funct3M,
    
    // Performance monitoring only; does not control CPU behavior.
    output logic [31:0] PCPlus4W_mon
);
    logic fence_iD;
    logic fence_iE;
    logic fence_i_wait;
    logic fence_i_start;
    logic HazardStallF;

    // ========================================================
    // INTERNAL SIGNALS
    // ========================================================

    // IF stage
    logic [31:0] PCPlus4F;
    logic [31:0] PC_BRAM;
    logic [31:0] PCPlus4_BRAM;

    logic FetchValidF;
    logic FetchFlushPendingF;

    // ID stage
    logic [31:0] rd1D, rd2D;
    logic [31:0] PCD;
    logic [4:0]  Rs1D, Rs2D, RdD;
    logic [31:0] ImmExtD;
    logic [31:0] PCPlus4D;

    // EX stage
    logic        regwriteE;
    logic [1:0]  result_srcE;
    logic        memwriteE;
    logic [3:0]  ALUcontrolE;
    logic        alu_srcE;
    logic [2:0]  ImmSrcE;

    logic [31:0] rd1E, rd2E, PCE;
    logic [31:0] ImmExtE, PCPlus4E;
    logic [31:0] WriteDataE, SrcA, SrcB, PCTargetE;
    logic [31:0] SrcAForwarded;
    logic [4:0]  Rs1E, Rs2E, RdE;

    // MEM stage
    logic        regwriteM;
    logic [1:0]  result_srcM;
    logic [4:0]  RdM;
    logic [31:0] PCPlus4M;

    // WB stage
    logic        regwriteW;
    logic [31:0] ALUresultW, ReadDataW, PCPlus4W;
    logic [1:0]  result_srcW;
    logic [31:0] ResultW;
    logic [4:0]  RdW;
    assign PCPlus4W_mon = PCPlus4W;

    // Hazard Unit
    logic        StallD;
    logic        FlushD;
    logic        FlushE;
    logic [1:0]  ForwardA, ForwardB;
    // FENCE.I detection: opcode 0001111, funct3 001.
    // This sideband flag follows the instruction from ID to EX.
    assign fence_iD =
        (InstrD[6:0]   == 7'b0001111) &&
        (InstrD[14:12] == 3'b001);

    // Generate one fence-start cycle, followed by one full
    // fetch-stall cycle so the preceding MEM-stage store can
    // complete its synchronous write to Instruction BRAM.
    assign fence_i_start = fence_iE && !fence_i_wait;

    // Keep the original hazard stall and add the FENCE.I stall.
    // Hazard_Unit must drive HazardStallF, not StallF directly.
    assign StallF = HazardStallF || fence_i_start || fence_i_wait;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            fence_iE     <= 1'b0;
            fence_i_wait <= 1'b0;
        end
        else begin
            fence_i_wait <= fence_i_start;

            // Match the ID/EX pipeline-register advance. A flush
            // kills the sideband flag just as it kills the instruction.
            if (fence_i_start || FlushE || PCSrc)
                fence_iE <= 1'b0;
            else
                fence_iE <= fence_iD;
        end
    end


    // ========================================================
    // STAGE 1: IF
    // ========================================================

    // Select next PC
    mux2 #(
        .WIDTH(32)
    ) pc_next_mux (
        .d0  (PCPlus4F),
        .d1  (PCTargetE),
        .sel (PCSrc),
        .y   (PCNextF)
    );

    // PC register
    always_ff @(posedge clk) begin
        if (reset)
            PCF <= 32'd0;
        else if (fence_i_start)
            // Restart fetch at the instruction immediately after FENCE.I.
            PCF <= PCPlus4E;
        else if (!StallF)
            PCF <= PCNextF;
    end

    // --------------------------------------------------------
    // Synchronous BRAM fetch alignment
    //
    // During load-use stall:
    //   - Hold PC_BRAM and PCPlus4_BRAM.
    //   - Hold FetchValidF and FetchFlushPendingF.
    //   - Keep branch/jump flush handling at higher priority.
    //
    // Instruction BRAM port A must also be disabled while
    // StallF is asserted. See the required top-level change.
    // --------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_BRAM            <= 32'd0;
            PCPlus4_BRAM       <= 32'd0;
            FetchValidF        <= 1'b0;
            FetchFlushPendingF <= 1'b0;
        end
        else begin
            // Keep BRAM address metadata aligned with InstrF.
            if (!StallF) begin
                PC_BRAM      <= PCF;
                PCPlus4_BRAM <= PCPlus4F;
            end

            // Branch/jump redirect has priority over ordinary fetch.
            if (PCSrc) begin
                FetchValidF        <= 1'b0;
                FetchFlushPendingF <= 1'b1;
            end
            // FENCE.I discards any already-prefetched instruction.
            else if (fence_i_start || fence_i_wait) begin
                FetchValidF        <= 1'b0;
                FetchFlushPendingF <= 1'b1;
            end
            // During a data-hazard or fence stall, hold fetch state.
            else if (!StallF) begin
                if (FetchFlushPendingF) begin
                    FetchValidF        <= 1'b1;
                    FetchFlushPendingF <= 1'b0;
                end
                else begin
                    FetchValidF <= 1'b1;
                end
            end
        end
    end

    // PC + 4
    adder #(
        .WIDTH(32)
    ) adderF (
        .d0 (PCF),
        .d1 (32'd4),
        .y  (PCPlus4F)
    );


    // ========================================================
    // PIPELINE REGISTER: IF/ID
    // ========================================================
    reg_if_id reg_id_if_pipeline (
        .clk      (clk),
        .reset    (reset),

        .EN       (!StallD && FetchValidF),
        .CLR      (FlushD || FetchFlushPendingF || !FetchValidF ||
                   fence_i_start || fence_i_wait),

        .InstrF   (InstrF),
        .PCF      (PC_BRAM),
        .PCPlus4F (PCPlus4_BRAM),

        .InstrD   (InstrD),
        .PCD      (PCD),
        .PCPlus4D (PCPlus4D)
    );


    // ========================================================
    // STAGE 2: ID
    // ========================================================
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD  = InstrD[11:7];

    Register_file Register_fileD (
        .clk  (clk),
        .we3  (regwriteW),
        .a1   (Rs1D),
        .a2   (Rs2D),
        .a3   (RdW),
        .wd3  (ResultW),
        .rd1  (rd1D),
        .rd2  (rd2D)
    );

    extend extendD (
        .Instr  (InstrD[31:7]),
        .ImmSrc (ImmSrcD),
        .ImmExt (ImmExtD)
    );


    // ========================================================
    // PIPELINE REGISTER: ID/EX
    // ========================================================
    reg_id_ex reg_id_ex_pipeline (
        .clk         (clk),
        .reset       (reset),
        .CLR         (FlushE || fence_i_start || fence_i_wait),

        .regwriteD   (regwriteD),
        .result_srcD (result_srcD),
        .mem_writeD  (memwriteD),
        .jumpD       (jumpD),
        .branchD     (branchD),
        .ALUcontrolD (ALUcontrolD),
        .alu_srcD    (alu_srcD),
        .ImmSrcD     (ImmSrcD),

        .rd1D        (rd1D),
        .rd2D        (rd2D),
        .PCD         (PCD),
        .Rs1D        (Rs1D),
        .Rs2D        (Rs2D),
        .RdD         (RdD),
        .ImmExtD     (ImmExtD),
        .PCPlus4D    (PCPlus4D),
        .funct3D     (InstrD[14:12]),

        .regwriteE   (regwriteE),
        .result_srcE (result_srcE),
        .mem_writeE  (memwriteE),
        .jumpE       (jumpE),
        .branchE     (branchE),
        .ALUcontrolE (ALUcontrolE),
        .alu_srcE    (alu_srcE),
        .ImmSrcE     (ImmSrcE),

        .rd1E        (rd1E),
        .rd2E        (rd2E),
        .PCE         (PCE),
        .Rs1E        (Rs1E),
        .Rs2E        (Rs2E),
        .RdE         (RdE),
        .ImmExtE     (ImmExtE),
        .PCPlus4E    (PCPlus4E),
        .funct3E     (funct3E)
    );


    // ========================================================
    // STAGE 3: EX
    // ========================================================

    // Forwarding mux for ALU input A
    mux3 #(
        .WIDTH(32)
    ) forwardA_mux (
        .d0  (rd1E),
        .d1  (ResultW),
        .d2  (ALUresultM),
        .sel (ForwardA),
        .y   (SrcAForwarded)
    );

    assign SrcA =
        (ImmSrcE == 3'b100) ? 32'd0 :
        (ImmSrcE == 3'b101) ? PCE :
                              SrcAForwarded;

    // Forwarding mux for ALU input B / store data
    mux3 #(
        .WIDTH(32)
    ) forwardB_mux (
        .d0  (rd2E),
        .d1  (ResultW),
        .d2  (ALUresultM),
        .sel (ForwardB),
        .y   (WriteDataE)
    );

    // ALU operand B selection
    mux2 #(
        .WIDTH(32)
    ) MUX2_ALUsrcE (
        .d0  (WriteDataE),
        .d1  (ImmExtE),
        .sel (alu_srcE),
        .y   (SrcB)
    );

    // ALU
    alu ALU_UNIT (
        .SrcA      (SrcA),
        .SrcB      (SrcB),
        .ALUcontrol(ALUcontrolE),
        .ALUresult (ALUResultE),
        .Zero      (ZeroE),
        .Less      (LessE)
    );

    // Branch / jump target
    always_comb begin
        if (jumpE && (ImmSrcE == 3'b000))
            PCTargetE = ALUResultE & 32'hFFFFFFFE; // JALR
        else
            PCTargetE = PCE + ImmExtE;              // JAL / branch
    end


    // ========================================================
    // PIPELINE REGISTER: EX/MEM
    // ========================================================
    reg_ex_mem reg_ex_mem_pipeline (
        .clk         (clk),
        .reset       (reset),

        .regwriteE   (regwriteE),
        .result_srcE (result_srcE),
        .mem_writeE  (memwriteE),
        .ALUresultE  (ALUResultE),
        .WriteDataE  (WriteDataE),
        .PCPlus4E    (PCPlus4E),
        .RdE         (RdE),
        .funct3E     (funct3E),

        .regwriteM   (regwriteM),
        .result_srcM (result_srcM),
        .mem_writeM  (mem_writeM),
        .ALUresultM  (ALUresultM),
        .WriteDataM  (WriteDataM),
        .PCPlus4M    (PCPlus4M),
        .RdM         (RdM),
        .funct3M     (funct3M)
    );


    // ========================================================
    // PIPELINE REGISTER: MEM/WB
    // ========================================================
    reg_mem_wb reg_mem_wb_pipeline (
        .clk         (clk),
        .reset       (reset),

        .regwriteM   (regwriteM),
        .result_srcM (result_srcM),
        .RAM_RD      (ReadDataM),
        .ALUresultM  (ALUresultM),
        .RdM         (RdM),
        .PCPlus4M    (PCPlus4M),

        .regwriteW   (regwriteW),
        .result_srcW (result_srcW),
        .ALUresultW  (ALUresultW),
        .ReadDataW   (ReadDataW),
        .RdW         (RdW),
        .PCPlus4W    (PCPlus4W)
    );


    // ========================================================
    // STAGE 5: WB
    // ========================================================
    mux3 #(
        .WIDTH(32)
    ) MUX3_ResultW (
        .d0  (ALUresultW),
        .d1  (ReadDataW),
        .d2  (PCPlus4W),
        .sel (result_srcW),
        .y   (ResultW)
    );


    // ========================================================
    // HAZARD UNIT
    //
    // Keep the existing load-use stall, forwarding, and
    // branch/jump flush logic unchanged.
    // ========================================================
    Hazard_Unit Hazard_Unit_datapath (
        .Rs1D      (Rs1D),
        .Rs2D      (Rs2D),
        .Rs1E      (Rs1E),
        .Rs2E      (Rs2E),

        .RdE       (RdE),
        .RdM       (RdM),
        .RdW       (RdW),

        .regwriteM (regwriteM),
        .regwriteW (regwriteW),
        .result_srcE(result_srcE),
        .PCsrcE    (PCSrc),

        .StallF    (HazardStallF),
        .StallD    (StallD),
        .FlushD    (FlushD),
        .FlushE    (FlushE),

        .ForwardA  (ForwardA),
        .ForwardB  (ForwardB)
    );

endmodule