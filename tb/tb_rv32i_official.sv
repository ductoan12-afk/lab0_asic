`timescale 1ns / 1ps

// ============================================================
// RV32UI-P TEST HARNESS
//
// PASS protocol from riscv-tests/env/p/riscv_test.h:
//
//   fence
//   li TESTNUM, 1
//   li a7, 93
//   li a0, 0
//   ecall
//
// FAIL protocol:
//
//   a7 = 93
//   a0 != 0
//   ecall
//
// This testbench does NOT require the CPU to implement CSR,
// SYSTEM, ECALL or FENCE.  The CPU may treat them as NOP;
// the testbench observes ECALL and acts as the host.
// ============================================================

module tb_rv32i_official;

    logic clk;
    logic reset;

    rv32i_top dut (
        .clk   (clk),
        .reset (reset)
    );

    always #5 clk = ~clk;

    integer cycles;
    integer timeout_cycles;

    bit test_done;
    bit test_pass;
    bit test_fail;

    initial begin
        clk           = 1'b0;
        reset         = 1'b1;

        cycles        = 0;
        timeout_cycles = 100000;

        test_done     = 1'b0;
        test_pass     = 1'b0;
        test_fail     = 1'b0;

        $display("============================================================");
        $display(" RV32UI-P OFFICIAL TEST HARNESS");
        $display(" PASS/FAIL protocol: ECALL (a7=93)");
        $display("============================================================");

        #20;
        reset = 1'b0;
    end

    // --------------------------------------------------------
    // Observe at falling edge so:
    // - InstrD is stable for the cycle
    // - register-file WB at negedge has completed after #1
    // --------------------------------------------------------
    always @(negedge clk) begin
        if (!reset && !test_done) begin

            cycles = cycles + 1;

            #1;

            // ECALL encoding = 0x00000073
            if (dut.Datapath.InstrD === 32'h00000073) begin

                $display("[TB] ECALL detected");
                $display("[TB] gp (x3)  = %08h", dut.Datapath.Register_fileD.register[3]);
                $display("[TB] a0 (x10) = %08h", dut.Datapath.Register_fileD.register[10]);
                $display("[TB] a7 (x17) = %08h", dut.Datapath.Register_fileD.register[17]);

                // Official PASS
                if ((dut.Datapath.Register_fileD.register[17] === 32'd93) &&
                    (dut.Datapath.Register_fileD.register[10] === 32'h00000000)) begin

                    test_pass = 1'b1;
                    test_done = 1'b1;

                    $display("[TB] ========================================");
                    $display("[TB] RV32UI-P TEST PASSED");
                    $display("[TB] ========================================");

                    $finish;
                end

                // Official FAIL
                else if ((dut.Datapath.Register_fileD.register[17] === 32'd93) &&
                         (dut.Datapath.Register_fileD.register[10] !== 32'h00000000)) begin

                    test_fail = 1'b1;
                    test_done = 1'b1;

                    $display("[TB] ========================================");
                    $display("[TB] RV32UI-P TEST FAILED");
                    $display("[TB] FAIL CODE = %08h",
                             dut.Datapath.Register_fileD.register[10]);
                    $display("[TB] ========================================");

                    $finish;
                end
            end

            // Timeout
            if (cycles >= timeout_cycles) begin

                test_done = 1'b1;

                $display("[TB] ========================================");
                $display("[TB] TIMEOUT");
                $display("[TB] cycles = %0d", cycles);
                $display("[TB] PCF    = %08h", dut.Datapath.PCF);
                $display("[TB] InstrF = %08h", dut.InstrF);
                $display("[TB] InstrD = %08h", dut.Datapath.InstrD);
                $display("[TB] ========================================");

                $finish;
            end
        end
    end

endmodule
