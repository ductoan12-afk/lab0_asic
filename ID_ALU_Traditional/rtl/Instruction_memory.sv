`timescale 1ns / 1ps

module Instruction_memory(
    input logic [31:0] a,
    output logic [31:0] rd
);

    // 16,000,000 words = 64 MB
    localparam integer IMEM_WORDS = 16_000_000;

    logic [31:0] ROM [0:IMEM_WORDS-1];
    string hex_file;

    initial begin
        if (!$value$plusargs("HEX=%s", hex_file))
            hex_file = "test_alu.hex";

        $display("[IMEM] Loading HEX: %s", hex_file);
        $readmemh(hex_file, ROM);
    end

    assign rd = (a[27:2] < IMEM_WORDS)
              ? ROM[a[27:2]]
              : 32'h00000013;

endmodule
