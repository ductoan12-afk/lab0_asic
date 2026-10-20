`timescale 1ns / 1ps

module rv32i_top_mmio_demo (
    input  logic        clk_p,
    input  logic        clk_n,
    input  logic        reset,
    input  logic [15:0] sw,
    input  logic [3:0]  btn,
    input  logic        uart_rx,
    output logic [15:0] led,
    output logic        uart_tx
);

    logic clk_cpu;
    logic clk_locked;
    logic [31:0] PCPlus4W_mon;

    logic reset_async;
    logic reset_cpu;
    logic [1:0] reset_sync;

    // UART RX data
    logic [7:0] uart_rx_data;
    logic       uart_rx_valid;
    logic       uart_rx_framing_error;
    logic       uart_rx_busy;

    // Loader control
    logic loader_hold_cpu;
    logic cpu_reset;

    logic [31:0] WriteDataM;
    logic [31:0] ALUresultM;
    logic        mem_writeM;

    // Instruction BRAM fetch stall
    logic fetch_stall;

    logic [4:0] btn_mmio;

    assign btn_mmio = {1'b0, btn};

    // ========================================================
    // RESET AND CLOCK
    // ========================================================

    clk_wiz_0 u_clk_wiz_0 (
        .clk_in1_p (clk_p),
        .clk_in1_n (clk_n),
        .reset     (reset),
        .clk_out1  (clk_cpu),
        .locked    (clk_locked)
    );

    assign reset_async = reset | ~clk_locked;

    always_ff @(posedge clk_cpu or posedge reset_async) begin
        if (reset_async)
            reset_sync <= 2'b11;
        else
            reset_sync <= {reset_sync[0], 1'b0};
    end

    assign reset_cpu = reset_sync[1];

    // Hold CPU while receiving and loading a test image.
    assign cpu_reset = reset_cpu | loader_hold_cpu;


    // ========================================================
    // UART RX
    // ========================================================

    UART_RX #(
        .CLOCK_FREQ_HZ (100_000_000),
        .BAUD_RATE     (115200)
    ) UART_RX_unit (
        .clk            (clk_cpu),
        .reset          (reset_cpu),
        .rx             (uart_rx),
        .rx_data        (uart_rx_data),
        .rx_valid       (uart_rx_valid),
        .framing_error  (uart_rx_framing_error),
        .busy           (uart_rx_busy)
    );


    // ========================================================
    // CPU DATAPATH SIGNALS
    // ========================================================

    // Instruction memory
    logic [31:0] PCF;
    logic [31:0] PCNextF;
    logic [31:0] InstrF;

    // Data memory
    logic [31:0] ReadDataM;

    // Controller
    logic [31:0] InstrD;

    logic        regwriteD;
    logic [1:0]  result_srcD;
    logic        memwriteD;
    logic        jumpD;
    logic        branchD;
    logic [3:0]  ALUcontrolD;
    logic        alu_srcD;
    logic [2:0]  ImmSrcD;

    logic        ZeroE;
    logic        LessE;
    logic [31:0] ALUResultE;
    logic        PCSrcE;

    logic        branchE;
    logic        jumpE;
    logic [2:0]  funct3E;
    logic [2:0]  funct3M;
    // ========================================================
// PERFORMANCE COUNTERS - MONITOR ONLY
// ========================================================

    localparam logic [31:0] PERF_TARGET_INSTR = 32'd10_000_000;
    
    (* MARK_DEBUG = "TRUE" *) logic [31:0] perf_cycle_count;
    (* MARK_DEBUG = "TRUE" *) logic [31:0] perf_retired_count;
    (* MARK_DEBUG = "TRUE" *) logic [31:0] perf_branch_count;
    (* MARK_DEBUG = "TRUE" *) logic [31:0] perf_taken_count;
    (* MARK_DEBUG = "TRUE" *) logic        perf_done;
    
    // Pipeline-aligned branch observation signals
    logic branch_m_mon;
    logic branch_taken_m_mon;
    logic branch_w_mon;
    logic branch_taken_w_mon;
    
    always_ff @(posedge clk_cpu or posedge cpu_reset) begin
        if (cpu_reset) begin
            perf_cycle_count   <= 32'd0;
            perf_retired_count <= 32'd0;
            perf_branch_count  <= 32'd0;
            perf_taken_count   <= 32'd0;
            perf_done          <= 1'b0;
    
            branch_m_mon       <= 1'b0;
            branch_taken_m_mon <= 1'b0;
            branch_w_mon       <= 1'b0;
            branch_taken_w_mon <= 1'b0;
        end
        else begin
            // Align branch observation with MEM and WB.
            branch_m_mon       <= branchE;
            branch_taken_m_mon <= branchE && PCSrcE;
    
            branch_w_mon       <= branch_m_mon;
            branch_taken_w_mon <= branch_taken_m_mon;
    
            if (!perf_done) begin
                // Count active CPU clock cycles, including stalls.
                perf_cycle_count <= perf_cycle_count + 32'd1;
    
                // PCPlus4W_mon follows the existing Lab 3 convention.
                if (PCPlus4W_mon != 32'd0) begin
                    if (branch_w_mon)
                        perf_branch_count <=
                            perf_branch_count + 32'd1;
    
                    if (branch_w_mon && branch_taken_w_mon)
                        perf_taken_count <=
                            perf_taken_count + 32'd1;
    
                    // Stop on exactly the 10,000,000th retirement.
                    if (perf_retired_count ==
                        PERF_TARGET_INSTR - 32'd1) begin
                        perf_retired_count <= PERF_TARGET_INSTR;
                        perf_done          <= 1'b1;
                    end
                    else begin
                        perf_retired_count <=
                            perf_retired_count + 32'd1;
                    end
                end
            end
        end
    end
    

    // ========================================================
    // CPU PIPELINE
    // ========================================================

    riscv_pipelined Datapath (
        .clk         (clk_cpu),
        .reset       (cpu_reset),
        .PCSrc       (PCSrcE),

        // Instruction memory
        .PCF         (PCF),
        .PCNextF     (PCNextF),
        .InstrF      (InstrF),
        .StallF      (fetch_stall),

        // Data memory
        .ALUresultM  (ALUresultM),
        .WriteDataM  (WriteDataM),
        .mem_writeM  (mem_writeM),
        .ReadDataM   (ReadDataM),

        // Controller
        .regwriteD   (regwriteD),
        .result_srcD (result_srcD),
        .memwriteD   (memwriteD),
        .jumpD       (jumpD),
        .branchD     (branchD),
        .ALUcontrolD (ALUcontrolD),
        .alu_srcD    (alu_srcD),
        .ImmSrcD     (ImmSrcD),
        .InstrD      (InstrD),

        .ZeroE       (ZeroE),
        .LessE       (LessE),
        .ALUResultE  (ALUResultE),

        .branchE     (branchE),
        .jumpE       (jumpE),
        .funct3E     (funct3E),
        .funct3M     (funct3M),
        .PCPlus4W_mon (PCPlus4W_mon)
    );


    // ========================================================
    // CONTROLLER
    // ========================================================

    Controller Controller_unit (
        .opcode      (InstrD[6:0]),
        .funct3D     (InstrD[14:12]),
        .funct7      (InstrD[30]),

        .branchE     (branchE),
        .jumpE       (jumpE),
        .funct3E     (funct3E),
        .ZeroE       (ZeroE),
        .LessE       (LessE),

        .regwriteD   (regwriteD),
        .ImmSrcD     (ImmSrcD),
        .alu_srcD    (alu_srcD),
        .memwriteD   (memwriteD),
        .result_srcD (result_srcD),
        .branchD     (branchD),
        .jumpD       (jumpD),
        .ALUcontrolD (ALUcontrolD),
        .PCSrcE      (PCSrcE)
    );


    // ========================================================
    // UART TEST LOADER
    // Instruction BRAM: 8192 x 32-bit
    // Byte Write Enable: DISABLED
    // ========================================================

    logic        loader_b_en;
    logic [3:0]  loader_b_we;
    logic [12:0] loader_b_addr;
    logic [31:0] loader_b_data;
    logic [31:0] loader_b_dout_unused;

    // Instruction BRAM Port B arbitration
    logic        imem_b_en;
    logic [3:0]  imem_b_we;
    logic [12:0] imem_b_addr;
    logic [31:0] imem_b_data;

    logic        cpu_imem_store;

    fpga_test_loader #(
        .BRAM_WORDS (8192)
    ) Test_Loader_unit (
        .clk       (clk_cpu),
        .reset     (reset_cpu),

        .rx_data   (uart_rx_data),
        .rx_valid  (uart_rx_valid),

        .cpu_hold  (loader_hold_cpu),

        .bram_en   (loader_b_en),
        .bram_we   (loader_b_we),
        .bram_addr (loader_b_addr),
        .bram_data (loader_b_data)
    );
    // ========================================================
// CPU STORE -> INSTRUCTION BRAM
//
// The test image occupies byte addresses 0x0000-0x7FFF.
// Port B is shared by the UART loader and CPU stores.
// UART loader has priority.
// ========================================================

    assign cpu_imem_store =
        mem_writeM && (ALUresultM[31:15] == 17'd0);

    always_comb begin
    // Default: no BRAM write
        imem_b_en   = 1'b0;
        imem_b_we   = 4'b0000;
        imem_b_addr = 13'd0;
        imem_b_data = 32'd0;

    // ----------------------------------------------------
    // Priority 1: UART loader
    // ----------------------------------------------------
        if (loader_b_en) begin
            imem_b_en   = loader_b_en;
            imem_b_we   = loader_b_we;
            imem_b_addr = loader_b_addr;
            imem_b_data = loader_b_data;
        end

    // ----------------------------------------------------
    // Priority 2: CPU store to the instruction-image range
    // ----------------------------------------------------
        else if (cpu_imem_store) begin
            imem_b_en   = 1'b1;
            imem_b_addr = ALUresultM[14:2];

            case (funct3M)

            // SB
                3'b000: begin
                    imem_b_data = {4{WriteDataM[7:0]}};
                    imem_b_we   = 4'b0001 << ALUresultM[1:0];
                end

            // SH
                3'b001: begin
                    imem_b_data = {2{WriteDataM[15:0]}};

                    if (ALUresultM[1] == 1'b0)
                        imem_b_we = 4'b0011;
                    else
                        imem_b_we = 4'b1100;
                end

            // SW
                3'b010: begin
                    imem_b_data = WriteDataM;
                    imem_b_we   = 4'b1111;
                end

                default: begin
                    imem_b_data = WriteDataM;
                    imem_b_we   = 4'b1111;
                end

            endcase
        end
    end


    // ========================================================
    // INSTRUCTION BRAM
    //
    // Port A: CPU instruction fetch
    // Port B: UART test loader
    //
    // Byte Write Enable DISABLED:
    // wea and web are each 1 bit.
    // ========================================================

        blk_mem_instruction_mmio Instruction_memory_unit (
        // Port A: CPU instruction fetch
        .clka  (clk_cpu),
        .ena   (!fetch_stall),
        .wea   (4'b0000),
        .addra (PCF[14:2]),
        .dina  (32'd0),
        .douta (InstrF),
    
        // Port B: UART loader and CPU instruction stores
        .clkb  (clk_cpu),
        .enb   (imem_b_en),
        .web   (imem_b_we),
        .addrb (imem_b_addr),
        .dinb  (imem_b_data),
        .doutb (loader_b_dout_unused)
    );


    // ========================================================
    // DATA MEMORY + MMIO
    // ========================================================

    Data_memory_mmio_fpga Data_MMIO_unit (
        .clk         (clk_cpu),

        // Keep Data RAM reset independent of loader_hold_cpu.
        .reset       (reset_cpu),

        .we          (mem_writeM),

        // MEM-stage CPU write interface
        .A           (ALUresultM),
        .wd          (WriteDataM),
        .funct3      (funct3M),

        // EX-stage CPU read interface
        .A_read      (ALUResultE),
        .funct3_read (funct3E),

        // UART image loader mirrors words into Data RAM.
        // loader_b_we is 1 bit because BRAM Byte Write Enable
        // is disabled.
        .loader_we (loader_b_en && (|loader_b_we)),
        .loader_addr (loader_b_addr),
        .loader_data (loader_b_data),

        .RD          (ReadDataM),

        .sw          (sw),
        .btn         (btn_mmio),
        .led         (led),
        .uart_tx     (uart_tx)
    );

endmodule