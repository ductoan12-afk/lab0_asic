`timescale 1ns / 1ps

// Simulation-only model for blk_mem_instruction_mmio.
// 8192 x 32-bit, synchronous read, 4 byte write enables.
// Port A is used for instruction fetch.
// Port B is shared by the loader and CPU stores.

module blk_mem_instruction_mmio (
    input  wire         clka,
    input  wire         ena,
    input  wire [3:0]   wea,
    input  wire [12:0]  addra,
    input  wire [31:0]  dina,
    output logic [31:0] douta,

    input  wire         clkb,
    input  wire         enb,
    input  wire [3:0]   web,
    input  wire [12:0]  addrb,
    input  wire [31:0]  dinb,
    output logic [31:0] doutb
);

    logic [31:0] mem [0:8191];

    // Port A: synchronous read, one-cycle latency.
    always @(posedge clka) begin
        if (ena) begin
            douta <= mem[addra];

            if (wea[0]) begin
                mem[addra][7:0] <= dina[7:0];
                douta[7:0]      <= dina[7:0];
            end

            if (wea[1]) begin
                mem[addra][15:8] <= dina[15:8];
                douta[15:8]      <= dina[15:8];
            end

            if (wea[2]) begin
                mem[addra][23:16] <= dina[23:16];
                douta[23:16]      <= dina[23:16];
            end

            if (wea[3]) begin
                mem[addra][31:24] <= dina[31:24];
                douta[31:24]      <= dina[31:24];
            end
        end
    end

    // Port B: synchronous read, byte-enabled writes.
    // Write-first behavior for enabled byte lanes.
    always @(posedge clkb) begin
        if (enb) begin
            doutb <= mem[addrb];

            if (web[0]) begin
                mem[addrb][7:0] <= dinb[7:0];
                doutb[7:0]      <= dinb[7:0];
            end

            if (web[1]) begin
                mem[addrb][15:8] <= dinb[15:8];
                doutb[15:8]      <= dinb[15:8];
            end

            if (web[2]) begin
                mem[addrb][23:16] <= dinb[23:16];
                doutb[23:16]      <= dinb[23:16];
            end

            if (web[3]) begin
                mem[addrb][31:24] <= dinb[31:24];
                doutb[31:24]      <= dinb[31:24];
            end
        end
    end

endmodule
