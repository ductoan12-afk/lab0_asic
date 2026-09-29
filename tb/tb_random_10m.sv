`timescale 1ns / 1ps

module tb_random_10m;

    // ------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------

    integer TARGET_INSTR;
    localparam integer MAX_EXTRA_INSTR = 2000;

    // Signature address used by random program.
    // Data_memory uses A[15:2], so this maps inside its 64-KB RAM.
    localparam logic [31:0] SIGNATURE_ADDR = 32'h80010700;

    // ------------------------------------------------------------
    // Clock / reset
    // ------------------------------------------------------------

    logic clk;
    logic reset;

    logic [31:0] WriteDataM;
    logic [31:0] ALUresultM;
    logic        mem_writeM;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    rv32i_top dut (
        .clk        (clk),
        .reset      (reset),
        .WriteDataM (WriteDataM),
        .ALUresultM (ALUresultM),
        .mem_writeM (mem_writeM)
    );

    // 100 MHz
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Test variables
    // ------------------------------------------------------------

    integer instr_count;
    integer fd;
    integer i;

    logic [31:0] last_pcf;
    logic [31:0] signature_value;

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    initial begin

        // Default target for the real test.
        // Can be overridden, e.g.:
        // +TARGET_INSTR=10000
        TARGET_INSTR = 10_000_000;

        if ($value$plusargs("TARGET_INSTR=%d", TARGET_INSTR))
            $display("[TB] TARGET_INSTR overridden to %0d",
                     TARGET_INSTR);

        clk            = 1'b0;
        reset          = 1'b1;
        instr_count    = 0;
        last_pcf       = 32'h00000000;
        signature_value = 32'h00000000;

        $display("==================================================");
        $display("[TB] RV32I RANDOM TEST");
        $display("[TB] TARGET_INSTR   = %0d", TARGET_INSTR);
        $display("[TB] SIGNATURE_ADDR = %08h", SIGNATURE_ADDR);
        $display("==================================================");

        // Reset
        repeat (5) @(posedge clk);
        reset = 1'b0;

        // First instruction is at PC = 0
        @(negedge clk);
        last_pcf    = dut.Datapath.PCF;
        instr_count = 1;

        $display("[TB] Start execution at PC=%08h", last_pcf);

        // --------------------------------------------------------
        // Monitor execution
        //
        // Random program is intentionally branch/jump free,
        // therefore PC advances sequentially by 4.
        //
        // instr_count therefore counts fetched instructions.
        // --------------------------------------------------------

        forever begin

            @(posedge clk);
            #1;

            // Count a newly fetched instruction.
            if (dut.Datapath.PCF != last_pcf) begin

                last_pcf = dut.Datapath.PCF;
                instr_count = instr_count + 1;

                // Progress message every million instructions
                if ((instr_count % 1_000_000) == 0) begin
                    $display("[TB] Instructions fetched = %0d   PC=%08h",
                             instr_count,
                             last_pcf);
                end
            end

            // ----------------------------------------------------
            // Final signature store
            //
            // Program performs:
            //   SW x31, 0x700(x20)
            //
            // with x20 = 0x80010000
            // => address = 0x80010700
            // ----------------------------------------------------

            if (mem_writeM &&
                (ALUresultM == SIGNATURE_ADDR)) begin

                signature_value = WriteDataM;

                $display("--------------------------------------------------");
                $display("[TB] SIGNATURE STORE DETECTED");
                $display("[TB] PC                = %08h",
                         dut.Datapath.PCF);
                $display("[TB] Instruction count  = %0d",
                         instr_count);
                $display("[TB] Signature          = %08h",
                         signature_value);

                // Require at least TARGET_INSTR fetched instructions.
                if (instr_count < TARGET_INSTR) begin
                    $display("[TB] TEST FAILED");
                    $display("[TB] Signature appeared before target.");
                    $display("[TB] target=%0d actual=%0d",
                             TARGET_INSTR,
                             instr_count);
                    $finish;
                end

                // Give pipeline enough cycles to finish WB.
                repeat (8) @(posedge clk);
                #1;

                // ------------------------------------------------
                // Save architectural register state
                // ------------------------------------------------

                fd = $fopen("work/sim/rtl_state.txt", "w");

                if (fd == 0) begin
                    $display("[TB] ERROR: cannot open");
                    $display("      work/sim/rtl_state.txt");
                    $finish;
                end

                $fwrite(fd,
                        "INSTR_COUNT %0d\n",
                        instr_count);

                $fwrite(fd,
                        "SIGNATURE %08h\n",
                        signature_value);

                for (i = 0; i < 32; i = i + 1) begin
                    $fwrite(fd,
                            "x%0d %08h\n",
                            i,
                            dut.Datapath.Register_fileD.register[i]);
                end

                $fclose(fd);

                $display("[TB] RTL state written to:");
                $display("      work/sim/rtl_state.txt");

                $display("[TB] TEST PASSED");
                $display("--------------------------------------------------");

                $finish;
            end

            // ----------------------------------------------------
            // Safety timeout
            // ----------------------------------------------------

            if (instr_count > (TARGET_INSTR + MAX_EXTRA_INSTR)) begin

                $display("--------------------------------------------------");
                $display("[TB] TEST FAILED");
                $display("[TB] Instruction limit exceeded.");
                $display("[TB] target=%0d actual=%0d",
                         TARGET_INSTR,
                         instr_count);
                $display("--------------------------------------------------");

                $finish;
            end
        end
    end

endmodule


