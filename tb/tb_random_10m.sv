`timescale 1ns / 1ps

module tb_random_10m;

    localparam integer TARGET_INSTR = 10_000_000;
    localparam logic [31:0] SIGNATURE_ADDR = 32'h0000FF00;
    localparam integer MAX_EXTRA_INSTR = 1000;

    logic clk;
    logic reset;

    logic [31:0] WriteDataM;
    logic [31:0] ALUresultM;
    logic mem_writeM;

    rv32i_top dut (
        .clk        (clk),
        .reset      (reset),
        .WriteDataM (WriteDataM),
        .ALUresultM (ALUresultM),
        .mem_writeM (mem_writeM)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    integer instr_count;
    logic [31:0] last_pcf;
    logic [31:0] sig_value;
    integer fd;
    integer i;

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        instr_count = 0;
        last_pcf = 32'h00000000;
        sig_value = 32'h00000000;

        // Giữ reset vài chu kỳ
        repeat (5) @(posedge clk);
        reset = 1'b0;

        // PC=0 là instruction đầu tiên
        @(negedge clk);
        last_pcf = dut.Datapath.PCF;
        instr_count = 1;

        $display("[TB] Start random test");
        $display("[TB] TARGET_INSTR = %0d", TARGET_INSTR);

        forever begin
            @(posedge clk);
            #1;

            // Chương trình random sẽ không branch/jump,
            // nên mỗi PCF thay đổi tương ứng với một instruction mới.
            if (dut.Datapath.PCF != last_pcf) begin
                last_pcf = dut.Datapath.PCF;
                instr_count = instr_count + 1;

                if ((instr_count % 1_000_000) == 0)
                    $display("[TB] Fetched %0d instructions, PC=%08h",
                             instr_count, last_pcf);
            end

            // Signature store ở cuối chương trình
            if (mem_writeM && (ALUresultM == SIGNATURE_ADDR)) begin
                sig_value = WriteDataM;

                $display("[TB] Signature store detected");
                $display("[TB] Instruction count = %0d", instr_count);
                $display("[TB] Signature         = %08h", sig_value);

                if (instr_count < TARGET_INSTR) begin
                    $display("[TB] ERROR: signature arrived before 10M instructions");
                    $finish;
                end

                // Cho pipeline hoàn tất WB
                repeat (8) @(posedge clk);
                #1;

                fd = $fopen("/tmp/c1_random/rtl_state.txt", "w");

                if (fd == 0) begin
                    $display("[TB] ERROR: cannot open rtl_state.txt");
                    $finish;
                end

                $fwrite(fd, "INSTR_COUNT %0d\n", instr_count);
                $fwrite(fd, "SIGNATURE %08h\n", sig_value);

                for (i = 0; i < 32; i = i + 1)
                    $fwrite(fd, "x%0d %08h\n",
                            i,
                            dut.Datapath.Register_fileD.register[i]);

                $fclose(fd);

                $display("[TB] RTL state written to /tmp/c1_random/rtl_state.txt");
                $display("[TB] TEST PASSED");
                $finish;
            end

            // Timeout nếu chương trình không tới signature
            if (instr_count > (TARGET_INSTR + MAX_EXTRA_INSTR)) begin
                $display("[TB] ERROR: exceeded instruction limit");
                $display("[TB] instr_count = %0d", instr_count);
                $finish;
            end
        end
    end

endmodule
