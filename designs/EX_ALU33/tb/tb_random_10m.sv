`timescale 1ns / 1ps

module tb_random_10m;

    // ------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------

    integer TARGET_INSTR;
    localparam integer MAX_EXTRA_INSTR = 2000;

    // ------------------------------------------------------------
    // Signature addresses
    //
    // Random program writes:
    //   0x83000700 = first signature word
    //   0x83000704 = second signature word
    // ------------------------------------------------------------

    localparam logic [31:0] SIGNATURE_ADDR  = 32'h83000700;
    localparam logic [31:0] SIGNATURE_ADDR2 = 32'h83000704;

    // Spike reference values
    localparam logic [31:0] REFERENCE_SIGNATURE1 = 32'hffb5b1c0;
    localparam logic [31:0] REFERENCE_SIGNATURE2 = 32'hb05a4700;

    // ------------------------------------------------------------
    // Clock / reset
    // ------------------------------------------------------------

    logic clk;
    logic reset;

    // ------------------------------------------------------------
    // DUT outputs
    // ------------------------------------------------------------

    logic [31:0] WriteDataM;
    logic [31:0] ALUresultM;
    logic        mem_writeM;

    // ------------------------------------------------------------
    // Signature
    // ------------------------------------------------------------

    logic [31:0] signature_value;
    logic [31:0] signature_value2;
    logic        signature_seen2;

    // ------------------------------------------------------------
    // Instruction counter
    // ------------------------------------------------------------

    integer instr_count;
    integer executed_count;

    // ------------------------------------------------------------
    // File
    // ------------------------------------------------------------

    integer fd;
    integer i;

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

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Reset
    // ------------------------------------------------------------

    initial begin
        reset = 1'b1;

        repeat (5) @(posedge clk);

        reset = 1'b0;
    end

    // ------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------

    initial begin

        TARGET_INSTR = 10_000_000;

        if ($value$plusargs("TARGET_INSTR=%d", TARGET_INSTR)) begin
            $display("[TB] TARGET_INSTR = %0d",
                     TARGET_INSTR);
        end
        else begin
            $display("[TB] TARGET_INSTR default = %0d",
                     TARGET_INSTR);
        end

        $display("[TB] SIGNATURE_ADDR  = %08h",
                 SIGNATURE_ADDR);

        $display("[TB] SIGNATURE_ADDR2 = %08h",
                 SIGNATURE_ADDR2);

        $display("[TB] REFERENCE_SIGNATURE1 = %08h",
                 REFERENCE_SIGNATURE1);

        $display("[TB] REFERENCE_SIGNATURE2 = %08h",
                 REFERENCE_SIGNATURE2);

    end

    // ------------------------------------------------------------
    // Counters
    // ------------------------------------------------------------

    initial begin

        instr_count    = 0;
        executed_count = 0;

        signature_value  = 32'b0;
        signature_value2 = 32'b0;
        signature_seen2  = 1'b0;

    end

    // ------------------------------------------------------------
    // Instruction fetch counter
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (!reset) begin

            instr_count = instr_count + 1;

            // ----------------------------------------------------
            // Count instructions that actually perform an
            // architectural write / control-flow action.
            // ----------------------------------------------------

            if (dut.Datapath.regwriteE ||
                dut.Datapath.memwriteE ||
                dut.Datapath.branchE  ||
                dut.Datapath.jumpE) begin

                executed_count = executed_count + 1;

            end

            // ----------------------------------------------------
            // Progress display every 1,000,000 fetched
            // instructions.
            // ----------------------------------------------------

            if ((instr_count % 1_000_000) == 0) begin

                $display("[TB] Fetched instructions = %0d PC=%08h",
                         instr_count,
                         dut.Datapath.PCF);

            end

            // ----------------------------------------------------
            // Safety limit
            // ----------------------------------------------------

            if (executed_count >
                (TARGET_INSTR + MAX_EXTRA_INSTR)) begin

                $display("==================================================");
                $display("[TB] ERROR: instruction limit exceeded");
                $display("[TB] target   = %0d",
                         TARGET_INSTR);
                $display("[TB] fetched  = %0d",
                         instr_count);
                $display("[TB] executed = %0d",
                         executed_count);
                $display("==================================================");

                $finish;

            end

            // ----------------------------------------------------
            // First signature word
            //
            // SW x31, 0x700(x20)
            //
            // Address:
            //   0x83000700
            // ----------------------------------------------------

            if (mem_writeM &&
                (ALUresultM == SIGNATURE_ADDR)) begin

                signature_value = WriteDataM;

                $display("==================================================");
                $display("[TB] SIGNATURE1 STORE DETECTED");
                $display("[TB] SIGNATURE1_ADDR  = %08h",
                         SIGNATURE_ADDR);
                $display("[TB] SIGNATURE1_VALUE = %08h",
                         signature_value);
                $display("[TB] fetched_count    = %0d",
                         instr_count);
                $display("[TB] executed_count  = %0d",
                         executed_count);
                $display("==================================================");

                // ------------------------------------------------
                // Require target instruction count
                // ------------------------------------------------

                if (instr_count < TARGET_INSTR) begin

                    $display("[TB] TEST FAILED");
                    $display("[TB] Signature appeared before target.");
                    $display("[TB] target=%0d actual=%0d",
                             TARGET_INSTR,
                             instr_count);

                    $finish;

                end

                // ------------------------------------------------
                // Wait for second signature word.
                //
                // Check every clock for up to 20 cycles.
                // ------------------------------------------------

                signature_seen2  = 1'b0;
                signature_value2 = 32'b0;

                for (i = 0; i < 20; i = i + 1) begin

                    @(posedge clk);
                    #1;

                    if (mem_writeM &&
                        (ALUresultM == SIGNATURE_ADDR2)) begin

                        signature_value2 = WriteDataM;
                        signature_seen2  = 1'b1;

                        $display("==================================================");
                        $display("[TB] SIGNATURE2 STORE DETECTED");
                        $display("[TB] SIGNATURE2_ADDR  = %08h",
                                 SIGNATURE_ADDR2);
                        $display("[TB] SIGNATURE2_VALUE = %08h",
                                 signature_value2);
                        $display("==================================================");

                        break;

                    end

                end

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
                        "EXECUTED_COUNT %0d\n",
                        executed_count);

                $fwrite(fd,
                        "SIGNATURE1 %08h\n",
                        signature_value);

                $fwrite(fd,
                        "SIGNATURE2 %08h\n",
                        signature_value2);

                for (i = 0; i < 32; i = i + 1) begin

                    $fwrite(fd,
                            "x%0d %08h\n",
                            i,
                            dut.Datapath.Register_fileD.register[i]);

                end

                $fclose(fd);

                $display("[TB] RTL state written to:");
                $display("      work/sim/rtl_state.txt");

                // ------------------------------------------------
                // Compare full 64-bit signature
                // ------------------------------------------------

                if (!signature_seen2) begin

                    $display("==================================================");
                    $display("[TB] TEST FAILED");
                    $display("[TB] Second signature word NOT detected.");
                    $display("==================================================");

                end
                else if ((signature_value ==
                          REFERENCE_SIGNATURE1) &&
                         (signature_value2 ==
                          REFERENCE_SIGNATURE2)) begin

                    $display("==================================================");
                    $display("[TB] TEST PASSED");
                    $display("[TB] Full 64-bit signature matches Spike reference");
                    $display("[TB] RTL SIGNATURE1 = %08h",
                             signature_value);
                    $display("[TB] REF SIGNATURE1 = %08h",
                             REFERENCE_SIGNATURE1);
                    $display("[TB] RTL SIGNATURE2 = %08h",
                             signature_value2);
                    $display("[TB] REF SIGNATURE2 = %08h",
                             REFERENCE_SIGNATURE2);
                    $display("[TB] fetched_count   = %0d",
                             instr_count);
                    $display("[TB] executed_count = %0d",
                             executed_count);
                    $display("==================================================");

                end
                else begin

                    $display("==================================================");
                    $display("[TB] TEST FAILED");
                    $display("[TB] Signature mismatch against Spike reference");
                    $display("[TB] RTL SIGNATURE1 = %08h",
                             signature_value);
                    $display("[TB] REF SIGNATURE1 = %08h",
                             REFERENCE_SIGNATURE1);
                    $display("[TB] RTL SIGNATURE2 = %08h",
                             signature_value2);
                    $display("[TB] REF SIGNATURE2 = %08h",
                             REFERENCE_SIGNATURE2);
                    $display("==================================================");

                end

                $finish;

            end

        end

    end

    // ------------------------------------------------------------
    // Timeout
    // ------------------------------------------------------------

    initial begin

        #120_000_000;

        $display("==================================================");
        $display("[TB] TIMEOUT");
        $display("[TB] fetched_count   = %0d",
                 instr_count);
        $display("[TB] executed_count = %0d",
                 executed_count);
        $display("==================================================");

        $finish;

    end

endmodule
