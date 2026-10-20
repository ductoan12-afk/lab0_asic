`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 04:54:34 PM
// Design Name: Nguyen Duc Toan
// Module Name: UART_TX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_TX #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE     = 115200
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx,
    output logic       busy
);

    // =====================================================
    // 1. TINH SO CHU KY CLOCK CHO MOI BIT UART
    // =====================================================
    localparam integer CLKS_PER_BIT =
        (CLOCK_FREQ_HZ + BAUD_RATE / 2) / BAUD_RATE;

    localparam integer COUNT_WIDTH =
        (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT) : 1;

    localparam logic [1:0] idle      = 2'b00;
    localparam logic [1:0] start_bit = 2'b01;
    localparam logic [1:0] data_bit  = 2'b10;
    localparam logic [1:0] stop_bit  = 2'b11;
    
    logic [1:0] state = idle;

    logic [COUNT_WIDTH-1:0] clk_count;
    logic [2:0]             bit_index;
    logic [7:0]             shift_reg;

    // UART san sang khi khong trong qua trinh truyen
    assign busy = (state != idle);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= idle;
            clk_count <= '0;
            bit_index <= '0;
            shift_reg <= 8'h00;
            tx        <= 1'b1;
        end
        else begin
            case (state)

                // -----------------------------------------
                // IDLE: KHONG TRUYEN DU LIEU
                // -----------------------------------------
                idle: begin
                    tx        <= 1'b1;
                    clk_count <= '0;
                    bit_index <= 3'd0;
                    state     <= idle;

                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx        <= 1'b0;
                        state     <= start_bit;
                    end
                end

                start_bit: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        bit_index <= 3'd0;

                        // Phat bit du lieu thap nhat truoc
                        tx    <= shift_reg[0];
                        state <= data_bit;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                data_bit : begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;

                        if (bit_index == 3'd7) begin
                            // Da xong bit du lieu thu 7
                            tx    <= 1'b1;
                            state <= stop_bit;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;

                            // Gui bit tiep theo
                            tx <= shift_reg[bit_index + 1'b1];
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                stop_bit: begin
                    tx <= 1'b1;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= '0;
                        state     <= idle;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                default: begin
                    state     <= idle;
                    clk_count <= '0;
                    bit_index <= '0;
                    shift_reg <= 8'h00;
                    tx        <= 1'b1;
                end

            endcase
        end
    end

endmodule
