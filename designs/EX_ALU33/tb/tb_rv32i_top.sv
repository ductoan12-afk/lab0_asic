`timescale 1ns / 1ps

module tb_rv32i_top();

    logic clk;
    logic reset;

    rv32i_top dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    integer f;
    integer i;

    initial begin
        clk = 0;
        reset = 1;

        $display("\n======================================================================");
        $display("          RUNNING RISCV-ARCH-TEST: I-add-00.S");
        $display("======================================================================");

        #12;
        reset = 0;

        // Cho mô ph?ng ch?y ?? th?i gian th?c thi test
        #3000;

        $display("\n----------------------------------------------------------------------");
        $display("          DUMPING SIGNATURE TO FILE...");
        $display("----------------------------------------------------------------------");

        f = $fopen("I-add-00.signature", "w");

        // Ghi các ô nh? ch?a k?t qu? Signature t? Data Memory ra file
        for (i = 0; i < 64; i = i + 1) begin
            $fdisplay(f, "%08h", dut.Data_memory_unit.RAM[i]);
        end

        $fclose(f);

        $display(">>> DUMP COMPLETED! Signature saved to I-add-00.signature <<<");
        $display("======================================================================\n");

        $finish;
    end

endmodule