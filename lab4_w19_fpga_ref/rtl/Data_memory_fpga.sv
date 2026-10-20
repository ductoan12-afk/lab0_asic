`timescale 1ns / 1ps

module Data_memory_fpga (
    input  logic        clk,
    input  logic        reset,
    input  logic        we,

    // Write side: MEM stage
    input  logic [31:0] A,
    input  logic [31:0] wd,
    input  logic [2:0]  funct3,

    // Read side: EX stage
    input  logic [31:0] A_read,
    input  logic [2:0]  funct3_read,

    // UART test loader write port
    input  logic        loader_we,
    input  logic [12:0] loader_addr,
    input  logic [31:0] loader_data,

    output logic [31:0] RD
);

    // ========================================================
    // DATA RAM: 16384 words x 32 bits = 64 KiB
    // ========================================================

    (* ram_style = "block" *)
    logic [31:0] RAM [0:16383];

    integer i;


    // ========================================================
    // WRITE CONTROL
    //
    // One shared RAM write port for CPU and UART loader.
    // Loader has priority while loading a test image.
    // ========================================================

    logic        ram_we_safe;
    logic        loader_write_active;
    logic        cpu_write_active;

    logic        ram_wr_en;
    logic [13:0] ram_wr_addr;
    logic [31:0] ram_wr_data;
    logic [3:0]  ram_wr_be;

    assign ram_we_safe =
        we && !reset;

    assign loader_write_active =
        loader_we && !reset;

    assign cpu_write_active =
        ram_we_safe && !loader_write_active;

    assign ram_wr_en =
        loader_write_active || cpu_write_active;


    // ========================================================
    // SHARED RAM WRITE ADDRESS / DATA / BYTE ENABLES
    // ========================================================

    always_comb begin
        ram_wr_addr = A[15:2];
        ram_wr_data = wd;
        ram_wr_be   = 4'b0000;

        if (loader_write_active) begin

            // Loader writes one complete 32-bit word.
            ram_wr_addr = {1'b0, loader_addr};
            ram_wr_data = loader_data;
            ram_wr_be   = 4'b1111;

        end
        else if (cpu_write_active) begin

            case (funct3)

                // ------------------------------------------------
                // SB: store one byte.
                // Replicate wd[7:0] across all four lanes so the
                // selected lane receives the correct source byte.
                // ------------------------------------------------

                3'b000: begin
                    ram_wr_data = {4{wd[7:0]}};
                    ram_wr_be   = 4'b0001 << A[1:0];
                end


                // ------------------------------------------------
                // SH: store one halfword.
                // Replicate wd[15:0] across both halfwords.
                // ------------------------------------------------

                3'b001: begin
                    ram_wr_data = {2{wd[15:0]}};

                    if (A[1] == 1'b0)
                        ram_wr_be = 4'b0011;
                    else
                        ram_wr_be = 4'b1100;
                end


                // ------------------------------------------------
                // SW: store one complete word.
                // ------------------------------------------------

                3'b010: begin
                    ram_wr_data = wd;
                    ram_wr_be   = 4'b1111;
                end


                // Preserve previous default behavior.
                default: begin
                    ram_wr_data = wd;
                    ram_wr_be   = 4'b1111;
                end

            endcase
        end
    end


    // ========================================================
    // SYNCHRONOUS READ OUTPUT REGISTERS
    // ========================================================

    logic [31:0] rd_word_q;
    logic [1:0]  rd_offset_q;
    logic [2:0]  rd_funct3_q;


    // ========================================================
    // STORE-TO-LOAD FORWARDING
    // ========================================================

    logic        rd_collision_q;
    logic [31:0] wr_data_q;
    logic [2:0]  wr_funct3_q;
    logic [1:0]  wr_offset_q;

    logic [31:0] rd_word_effective;


    // ========================================================
    // MERGE A CPU STORE INTO AN EXISTING 32-BIT WORD
    // Uses the original CPU write data for forwarding.
    // ========================================================

    function automatic logic [31:0] merge_store_word (
        input logic [31:0] old_word,
        input logic [31:0] write_data,
        input logic [2:0]  store_funct3,
        input logic [1:0]  byte_offset
    );
        begin
            merge_store_word = old_word;

            case (store_funct3)

                // SB
                3'b000: begin
                    case (byte_offset)

                        2'b00:
                            merge_store_word[7:0] =
                                write_data[7:0];

                        2'b01:
                            merge_store_word[15:8] =
                                write_data[7:0];

                        2'b10:
                            merge_store_word[23:16] =
                                write_data[7:0];

                        2'b11:
                            merge_store_word[31:24] =
                                write_data[7:0];

                    endcase
                end


                // SH
                3'b001: begin
                    if (byte_offset[1] == 1'b0)
                        merge_store_word[15:0] =
                            write_data[15:0];
                    else
                        merge_store_word[31:16] =
                            write_data[15:0];
                end


                // SW
                3'b010:
                    merge_store_word = write_data;


                // Preserve previous RTL default behavior.
                default:
                    merge_store_word = write_data;

            endcase
        end
    endfunction


    // ========================================================
    // INITIAL CONTENTS
    // Preserve existing memory initialization.
    // ========================================================

    initial begin
        for (i = 0; i < 16384; i = i + 1)
            RAM[i] = 32'd0;

        $readmemh("alu_ref.hex", RAM, 0, 19);
    end


    // ========================================================
    // SYNCHRONOUS READ + SHARED SYNCHRONOUS WRITE
    // ========================================================

    always_ff @(posedge clk) begin

        // Synchronous read from EX-stage address
        rd_word_q   <= RAM[A_read[15:2]];
        rd_offset_q <= A_read[1:0];
        rd_funct3_q <= funct3_read;


        // Detect CPU same-word read/write collision.
        // Loader writes are excluded from CPU forwarding.
        rd_collision_q <=
            cpu_write_active &&
            (A[31:16]      == 16'h0000) &&
            (A_read[31:16] == 16'h0000) &&
            (A[15:2]       == A_read[15:2]);


        // Save original CPU write data for forwarding.
        // Do not save the replicated byte-lane write data.
        wr_data_q   <= wd;
        wr_funct3_q <= funct3;
        wr_offset_q <= A[1:0];


        // ----------------------------------------------------
        // ONE RAM WRITE PORT, WITH BYTE ENABLES
        // ----------------------------------------------------

        if (ram_wr_en) begin

            if (ram_wr_be[0])
                RAM[ram_wr_addr][7:0] <=
                    ram_wr_data[7:0];

            if (ram_wr_be[1])
                RAM[ram_wr_addr][15:8] <=
                    ram_wr_data[15:8];

            if (ram_wr_be[2])
                RAM[ram_wr_addr][23:16] <=
                    ram_wr_data[23:16];

            if (ram_wr_be[3])
                RAM[ram_wr_addr][31:24] <=
                    ram_wr_data[31:24];

        end
    end


    // ========================================================
    // SAME-WORD STORE-TO-LOAD FORWARDING
    // ========================================================

    always_comb begin
        rd_word_effective = rd_word_q;

        if (rd_collision_q) begin
            rd_word_effective = merge_store_word(
                rd_word_q,
                wr_data_q,
                wr_funct3_q,
                wr_offset_q
            );
        end
    end


    // ========================================================
    // LOAD DATA FORMATTING
    // LB / LH / LW / LBU / LHU
    // ========================================================

    always_comb begin
        RD = rd_word_effective;

        case (rd_funct3_q)

            // LB: sign-extend byte
            3'b000: begin
                case (rd_offset_q)

                    2'b00:
                        RD = {{24{rd_word_effective[7]}},
                              rd_word_effective[7:0]};

                    2'b01:
                        RD = {{24{rd_word_effective[15]}},
                              rd_word_effective[15:8]};

                    2'b10:
                        RD = {{24{rd_word_effective[23]}},
                              rd_word_effective[23:16]};

                    2'b11:
                        RD = {{24{rd_word_effective[31]}},
                              rd_word_effective[31:24]};

                endcase
            end


            // LH: sign-extend halfword
            3'b001: begin
                if (rd_offset_q[1] == 1'b0)
                    RD = {{16{rd_word_effective[15]}},
                          rd_word_effective[15:0]};
                else
                    RD = {{16{rd_word_effective[31]}},
                          rd_word_effective[31:16]};
            end


            // LW
            3'b010:
                RD = rd_word_effective;


            // LBU: zero-extend byte
            3'b100: begin
                case (rd_offset_q)

                    2'b00:
                        RD = {24'd0, rd_word_effective[7:0]};

                    2'b01:
                        RD = {24'd0, rd_word_effective[15:8]};

                    2'b10:
                        RD = {24'd0, rd_word_effective[23:16]};

                    2'b11:
                        RD = {24'd0, rd_word_effective[31:24]};

                endcase
            end


            // LHU: zero-extend halfword
            3'b101: begin
                if (rd_offset_q[1] == 1'b0)
                    RD = {16'd0, rd_word_effective[15:0]};
                else
                    RD = {16'd0, rd_word_effective[31:16]};
            end


            default:
                RD = rd_word_effective;

        endcase
    end

endmodule