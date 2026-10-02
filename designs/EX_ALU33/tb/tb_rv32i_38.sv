`timescale 1ns / 1ps

// ============================================================================
// RV32I 38-TEST SELF-CHECKING TESTBENCH
//
// 38 checks = 37 RV32I instruction tests + 1 "simple/reached-end" smoke test.
// This testbench deliberately does NOT depend on CSR/SYSTEM/FENCE/ECALL.
// It runs together with rv32i_38_final.hex.
// ============================================================================
module tb_rv32i_38;

    logic clk;
    logic reset;

    rv32i_top dut (
        .clk   (clk),
        .reset (reset)
    );

    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer cycles;
    bit completed;

    task automatic check_word(
        input integer index,
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string name
    );
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS %02d] %-8s actual=%08h expected=%08h",
                         index, name, actual, expected);
            end
            else begin
                fail_count = fail_count + 1;
                $display("[FAIL %02d] %-8s actual=%08h expected=%08h",
                         index, name, actual, expected);
            end
        end
    endtask

    // Signature area in Data_memory:
    // 0x200 + 4*index, index 0..33.
    function automatic logic [31:0] sig(input integer index);
        sig = dut.Data_memory_unit.RAM[(32'h00000200 + index*4) >> 2];
    endfunction

    initial begin
        clk        = 1'b0;
        reset      = 1'b1;
        pass_count = 0;
        fail_count = 0;
        cycles     = 0;
        completed  = 1'b0;

        $display("===============================================================");
        $display(" RV32I 38-TEST SELF CHECK");
        $display(" HEX = sw/rv32i_38_final.hex");
        $display("===============================================================");

        #20;
        reset = 1'b0;

        // Wait until the final smoke marker is stored at Data RAM 0x288.
        // This means the program reached the end of all tests.
        fork
            begin : wait_done
                forever begin
                    @(posedge clk);
                    cycles = cycles + 1;

                    if (dut.Data_memory_unit.we &&
                        (dut.Data_memory_unit.A === 32'h00000288) &&
                        (dut.Data_memory_unit.wd === 32'h00000026)) begin
                        completed = 1'b1;
                        disable wait_done;
                    end
                end
            end

            begin : timeout_watch
                #20000;
                $display("[TB] TIMEOUT: program did not reach final marker");
                $display("[TB] PCF=%08h InstrF=%08h InstrD=%08h",
                         dut.Datapath.PCF,
                         dut.InstrF,
                         dut.Datapath.InstrD);
                $display("[TB] This is a CPU/program-flow failure, not a PASS.");
                $finish;
            end
        join_any
        disable timeout_watch;

        // Allow the final store to commit and let the pipeline settle.
        repeat (5) @(posedge clk);
        #1;

        $display("");
        $display("===============================================================");
        $display(" RESULT");
        $display("===============================================================");

        // 1..21: ALU/U-type
        check_word( 1, sig( 0), 32'h00000008, "ADD");
        check_word( 2, sig( 1), 32'h00000005, "ADDI");
        check_word( 3, sig( 2), 32'h00000001, "AND");
        check_word( 4, sig( 3), 32'h00000001, "ANDI");
        check_word( 5, sig( 4), 32'h00000007, "OR");
        check_word( 6, sig( 5), 32'h0000000D, "ORI");
        check_word( 7, sig( 6), 32'h00000006, "XOR");
        check_word( 8, sig( 7), 32'h0000000A, "XORI");
        check_word( 9, sig( 8), 32'h00000028, "SLL");
        check_word(10, sig( 9), 32'h00000028, "SLLI");
        check_word(11, sig(10), 32'h1FFFFFFE, "SRL");
        check_word(12, sig(11), 32'h00000005, "SRLI");
        check_word(13, sig(12), 32'hFFFFFFFE, "SRA");
        check_word(14, sig(13), 32'hFFFFFFFC, "SRAI");
        check_word(15, sig(14), 32'h00000001, "SLT");
        check_word(16, sig(15), 32'h00000000, "SLTU");
        check_word(17, sig(16), 32'h00000001, "SLTI");
        check_word(18, sig(17), 32'h00000000, "SLTIU");
        check_word(19, sig(18), 32'h12345000, "LUI");
        check_word(20, sig(19), 32'h000000A8, "AUIPC");
        check_word(21, sig(20), 32'h00000002, "SUB");

        // 22..23: jumps
        check_word(22, sig(21), 32'h000000BC, "JAL");
        check_word(23, sig(22), 32'h000000D0, "JALR");

        // 24..28: loads
        check_word(24, sig(23), 32'h11223344, "LW");
        check_word(25, sig(24), 32'h00000001, "LB");
        check_word(26, sig(25), 32'h000000FF, "LBU");
        check_word(27, sig(26), 32'h00007F01, "LH");
        check_word(28, sig(27), 32'h000080FF, "LHU");

        // 29..34: branches
        check_word(29, sig(28), 32'h00000001, "BEQ");
        check_word(30, sig(29), 32'h00000002, "BNE");
        check_word(31, sig(30), 32'h00000003, "BLT");
        check_word(32, sig(31), 32'h00000004, "BGE");
        check_word(33, sig(32), 32'h00000005, "BLTU");
        check_word(34, sig(33), 32'h00000006, "BGEU");

        // 35..37: direct store checks. These are intentionally read directly
        // from Data_memory RAM instead of using another load instruction.
        check_word(35,
                   dut.Data_memory_unit.RAM[32'h00000100 >> 2],
                   32'h11223344,
                   "SW");

        check_word(36,
                   dut.Data_memory_unit.RAM[32'h00000104 >> 2],
                   32'h1122AA44,
                   "SB");

        check_word(37,
                   dut.Data_memory_unit.RAM[32'h00000108 >> 2],
                   32'h07FF3344,
                   "SH");

        // 38: simple/smoke marker. 0x26 = decimal 38.
        check_word(38,
                   dut.Data_memory_unit.RAM[32'h00000288 >> 2],
                   32'h00000026,
                   "SIMPLE");

        $display("");
        $display("===============================================================");
        $display(" PASS = %0d / 38", pass_count);
        $display(" FAIL = %0d / 38", fail_count);
        if (fail_count == 0 && pass_count == 38)
            $display(">>> ALL 38 TESTS PASSED <<<");
        else
            $display(">>> RV32I TEST FAILED <<<");
        $display("===============================================================");

        $finish;
    end

endmodule
