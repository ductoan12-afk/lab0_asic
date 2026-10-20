`timescale 1ns / 1ps

module fpga_test_loader #(
    parameter integer BRAM_WORDS = 8192
)(
    input  logic        clk,
    input  logic        reset,

    input  logic [7:0]  rx_data,
    input  logic        rx_valid,

    output logic        cpu_hold,
    output logic        bram_en,
    output logic [3:0]  bram_we,
    output logic [12:0] bram_addr,
    output logic [31:0] bram_data
);

    typedef enum logic [2:0] {
        WAIT_L,
        WAIT_O,
        WAIT_A,
        WAIT_D,
        LOAD_LENGTH,
        LOAD_DATA,
        DRAIN_WRITE
    } state_t;

    state_t state;

    logic [31:0] load_word_count;
    logic [31:0] received_words;
    logic [1:0]  length_byte_index;
    logic [1:0]  data_byte_index;

    logic [12:0] write_addr;
    logic [31:0] word_buffer;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state             <= WAIT_L;
            cpu_hold          <= 1'b1;

            bram_en           <= 1'b0;
            bram_we <= 4'b0000;
            bram_addr         <= 13'd0;
            bram_data         <= 32'd0;

            load_word_count   <= 32'd0;
            received_words    <= 32'd0;
            length_byte_index <= 2'd0;
            data_byte_index   <= 2'd0;

            write_addr        <= 13'd0;
            word_buffer       <= 32'd0;
        end
        else begin
            bram_en <= 1'b0;
            bram_we <= 4'b0000;

            case (state)

                WAIT_L: begin
                    if (rx_valid && rx_data == 8'h4C)
                        state <= WAIT_O;
                end

                WAIT_O: begin
                    if (rx_valid) begin
                        if (rx_data == 8'h4F)
                            state <= WAIT_A;
                        else if (rx_data == 8'h4C)
                            state <= WAIT_O;
                        else
                            state <= WAIT_L;
                    end
                end

                WAIT_A: begin
                    if (rx_valid) begin
                        if (rx_data == 8'h41)
                            state <= WAIT_D;
                        else if (rx_data == 8'h4C)
                            state <= WAIT_O;
                        else
                            state <= WAIT_L;
                    end
                end

                WAIT_D: begin
                    if (rx_valid) begin
                        if (rx_data == 8'h44) begin
                            cpu_hold          <= 1'b1;

                            load_word_count   <= 32'd0;
                            received_words    <= 32'd0;
                            length_byte_index <= 2'd0;
                            data_byte_index   <= 2'd0;

                            write_addr        <= 13'd0;
                            word_buffer       <= 32'd0;

                            state <= LOAD_LENGTH;
                        end
                        else if (rx_data == 8'h4C)
                            state <= WAIT_O;
                        else
                            state <= WAIT_L;
                    end
                end

                LOAD_LENGTH: begin
                    if (rx_valid) begin
                        case (length_byte_index)

                            2'd0: begin
                                load_word_count[7:0] <= rx_data;
                                length_byte_index <= 2'd1;
                            end

                            2'd1: begin
                                load_word_count[15:8] <= rx_data;
                                length_byte_index <= 2'd2;
                            end

                            2'd2: begin
                                load_word_count[23:16] <= rx_data;
                                length_byte_index <= 2'd3;
                            end

                            2'd3: begin
                                if (
                                    ({rx_data, load_word_count[23:0]} != 32'd0) &&
                                    ({rx_data, load_word_count[23:0]} <= BRAM_WORDS)
                                ) begin
                                    load_word_count <= {
                                        rx_data,
                                        load_word_count[23:0]
                                    };

                                    received_words  <= 32'd0;
                                    write_addr      <= 13'd0;
                                    data_byte_index <= 2'd0;
                                    word_buffer     <= 32'd0;

                                    state <= LOAD_DATA;
                                end
                                else begin
                                    state <= WAIT_L;
                                end

                                length_byte_index <= 2'd0;
                            end

                        endcase
                    end
                end

                LOAD_DATA: begin
                    if (rx_valid) begin
                        case (data_byte_index)

                            2'd0: begin
                                word_buffer[7:0] <= rx_data;
                                data_byte_index <= 2'd1;
                            end

                            2'd1: begin
                                word_buffer[15:8] <= rx_data;
                                data_byte_index <= 2'd2;
                            end

                            2'd2: begin
                                word_buffer[23:16] <= rx_data;
                                data_byte_index <= 2'd3;
                            end

                            2'd3: begin
                                bram_addr <= write_addr;
                                bram_data <= {
                                    rx_data,
                                    word_buffer[23:0]
                                };

                                bram_en <= 1'b1;
                                bram_we <= 4'b1111;

                                data_byte_index <= 2'd0;
                                received_words <= received_words + 1'b1;

                                if ((received_words + 1'b1) >= load_word_count)
                                    state <= DRAIN_WRITE;
                                else
                                    write_addr <= write_addr + 1'b1;
                            end

                        endcase
                    end
                end

                DRAIN_WRITE: begin
                    cpu_hold <= 1'b0;
                    state <= WAIT_L;
                end

                default: begin
                    state    <= WAIT_L;
                    bram_en  <= 1'b0;
                    bram_we <= 4'b0000;
                    cpu_hold <= 1'b1;
                end

            endcase
        end
    end

endmodule