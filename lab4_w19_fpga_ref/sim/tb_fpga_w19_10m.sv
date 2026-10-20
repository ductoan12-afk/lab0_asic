`timescale 1ns / 1ps

module tb_fpga_w19_10m;

    logic clk_p = 1'b0;
    wire  clk_n;
    logic reset = 1'b1;

    logic [15:0] sw;
    logic [3:0]  btn;
    logic        uart_rx;

    wire [15:0] led;
    wire        uart_tx;

    string hex_file;
    real cpi;
    real branch_pct;
    real taken_pct;

    assign clk_n = ~clk_p;

    // 200 MHz differential reference clock.
    always #2.5 clk_p = ~clk_p;

    rv32i_top_mmio_demo dut (
        .clk_p   (clk_p),
        .clk_n   (clk_n),
        .reset   (reset),
        .sw      (sw),
        .btn     (btn),
        .uart_rx (uart_rx),
        .led     (led),
        .uart_tx (uart_tx)
    );

    initial begin
        sw      = 16'd0;
        btn     = 4'd0;
        uart_rx = 1'b1;

        if (!$value$plusargs("HEX=%s", hex_file))
            $fatal(1, "Missing +HEX=path/to/branch_N.hex");

        // Allow the clock wizard model to start.
        repeat (8) @(posedge clk_p);
        @(negedge clk_p);
        reset = 1'b0;

        wait (dut.clk_locked === 1'b1);
        repeat (8) @(posedge dut.clk_cpu);
        #1;

        // Match the FPGA loader's final memory contents:
        // the same image is written to instruction BRAM and data RAM.
        $display("[TB] Loading image: %s", hex_file);
        $readmemh(hex_file, dut.Instruction_memory_unit.mem);
        $readmemh(hex_file, dut.Data_MMIO_unit.Data_RAM.RAM);

        // Simulation-only shortcut: bypass the UART loader handshake.
        // CPU and performance counters remain in reset until released.
        force dut.loader_hold_cpu = 1'b0;

        $display("[TB] Starting measurement at 10,000,000 retirements.");

        wait (dut.perf_done === 1'b1);

        cpi = $itor(dut.perf_cycle_count) /
              $itor(dut.perf_retired_count);

        branch_pct = 100.0 * $itor(dut.perf_branch_count) /
                     $itor(dut.perf_retired_count);

        if (dut.perf_branch_count != 0)
            taken_pct = 100.0 * $itor(dut.perf_taken_count) /
                        $itor(dut.perf_branch_count);
        else
            taken_pct = 0.0;

        $display("");
        $display("========== FPGA TOP W19 RESULT ==========");
        $display("HEX             = %s", hex_file);
        $display("Retired         = %0d", dut.perf_retired_count);
        $display("Cycles          = %0d", dut.perf_cycle_count);
        $display("Branch count    = %0d", dut.perf_branch_count);
        $display("Taken count     = %0d", dut.perf_taken_count);
        $display("CPI             = %0.8f", cpi);
        $display("Branch rate (%%) = %0.6f", branch_pct);
        $display("Taken / branch (%%) = %0.6f", taken_pct);
        $display("=========================================");
        $finish;
    end

    // Stop if the program never reaches the target retirement count.
    initial begin
        #500_000_000;
        $fatal(1, "TIMEOUT: perf_done was not reached.");
    end

endmodule
