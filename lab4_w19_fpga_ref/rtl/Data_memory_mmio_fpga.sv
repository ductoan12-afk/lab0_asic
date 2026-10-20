`timescale 1ns / 1ps

module Data_memory_mmio_fpga (
    input  logic        clk,
    input  logic        reset,

    input  logic        we,
    input  logic [31:0] A,
    input  logic [31:0] wd,
    input  logic [2:0]  funct3,

    input  logic [31:0] A_read,
    input  logic [2:0]  funct3_read,

    // UART test loader interface
    input  logic        loader_we,
    input  logic [12:0] loader_addr,
    input  logic [31:0] loader_data,

    output logic [31:0] RD,

    input  logic [15:0] sw,
    input  logic [4:0]  btn,
    output logic [15:0] led,

    output logic        uart_tx
);

    // ========================================================
    // 1. MEMORY MAP
    // ========================================================
    localparam logic [31:0] LED_ADDR =
        32'h1000_0000;

    localparam logic [31:0] SW_ADDR =
        32'h1000_0004;

    localparam logic [31:0] BTN_ADDR =
        32'h1000_0008;

    localparam logic [31:0] UART_DATA_ADDR =
        32'h1000_000C;

    localparam logic [31:0] UART_STATUS_ADDR =
        32'h1000_0010;


    // ========================================================
    // 2. INTERNAL SIGNALS
    // ========================================================

    logic [31:0] ram_rd;
    logic [31:0] mmio_rd_q;

    // MEM-stage address selectors
    logic ram_sel;
    logic led_sel;
    logic sw_sel;
    logic btn_sel;
    logic uart_data_sel;
    logic uart_status_sel;

    // EX-stage read selectors
    logic led_sel_read;
    logic sw_sel_read;
    logic btn_sel_read;
    logic uart_status_sel_read;

    // LED store-to-load forwarding
    logic [15:0] led_next_for_read;
    logic same_led_word_read_write;

    // UART control signals
    logic uart_tx_busy;
    logic uart_start;


    // ========================================================
    // 3. ADDRESS DECODING: MEM STAGE
    // ========================================================

    assign ram_sel =
        (A[31:16] == 16'h0000);

    assign led_sel =
        (A[31:2] == LED_ADDR[31:2]);

    assign sw_sel =
        (A[31:2] == SW_ADDR[31:2]);

    assign btn_sel =
        (A[31:2] == BTN_ADDR[31:2]);

    assign uart_data_sel =
        (A[31:2] == UART_DATA_ADDR[31:2]);

    assign uart_status_sel =
        (A[31:2] == UART_STATUS_ADDR[31:2]);


    // ========================================================
    // 4. ADDRESS DECODING: EX-STAGE READ REQUEST
    // ========================================================

    assign led_sel_read =
        (A_read[31:2] == LED_ADDR[31:2]);

    assign sw_sel_read =
        (A_read[31:2] == SW_ADDR[31:2]);

    assign btn_sel_read =
        (A_read[31:2] == BTN_ADDR[31:2]);

    assign uart_status_sel_read =
        (A_read[31:2] == UART_STATUS_ADDR[31:2]);


    // ========================================================
    // 5. DATA RAM
    //
    // CPU memory interface remains unchanged.
    // Loader signals are passed through to Data_memory_fpga.
    // ========================================================

    Data_memory_fpga Data_RAM (
        .clk         (clk),
        .reset       (reset),
        .we          (we && ram_sel),

        // MEM-stage CPU write interface
        .A           (A),
        .wd          (wd),
        .funct3      (funct3),

        // EX-stage CPU read interface
        .A_read      (A_read),
        .funct3_read (funct3_read),

        // UART loader write interface
        .loader_we   (loader_we),
        .loader_addr (loader_addr),
        .loader_data (loader_data),

        .RD          (ram_rd)
    );


    // ========================================================
    // 6. UART TX
    // ========================================================

    assign uart_start =
        !reset &&
        we &&
        uart_data_sel &&
        (A[1:0] == 2'b00) &&
        ((funct3 == 3'b000) || (funct3 == 3'b010)) &&
        !uart_tx_busy;

    UART_TX #(
        .CLOCK_FREQ_HZ (100_000_000),
        .BAUD_RATE     (115200)
    ) UART_TX_unit (
        .clk      (clk),
        .reset    (reset),
        .tx_start (uart_start),
        .tx_data  (wd[7:0]),
        .tx       (uart_tx),
        .busy     (uart_tx_busy)
    );


    // ========================================================
    // 7. LED STORE-TO-LOAD FORWARDING
    // ========================================================

    assign same_led_word_read_write =
        we &&
        led_sel &&
        led_sel_read &&
        (A[31:2] == A_read[31:2]);

    always_comb begin
        led_next_for_read = led;

        if (same_led_word_read_write) begin
            case (funct3)

                // SB
                3'b000: begin
                    case (A[1:0])
                        2'b00:
                            led_next_for_read[7:0] = wd[7:0];

                        2'b01:
                            led_next_for_read[15:8] = wd[7:0];

                        default: ;
                    endcase
                end

                // SH
                3'b001: begin
                    if (A[1:0] == 2'b00)
                        led_next_for_read = wd[15:0];
                end

                // SW
                3'b010: begin
                    if (A[1:0] == 2'b00)
                        led_next_for_read = wd[15:0];
                end

                default: ;

            endcase
        end
    end


    // ========================================================
    // 8. REGISTERED MMIO READ
    //
    // UART STATUS:
    //   bit 0 = ready
    //   bit 1 = busy
    // ========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            mmio_rd_q <= 32'd0;
        end
        else if (led_sel_read) begin
            mmio_rd_q <= {16'd0, led_next_for_read};
        end
        else if (sw_sel_read) begin
            mmio_rd_q <= {16'd0, sw};
        end
        else if (btn_sel_read) begin
            mmio_rd_q <= {27'd0, btn};
        end
        else if (uart_status_sel_read) begin
            mmio_rd_q <= {
                30'd0,
                uart_tx_busy,
                ~uart_tx_busy
            };
        end
        else begin
            mmio_rd_q <= 32'd0;
        end
    end


    // ========================================================
    // 9. MMIO WRITE: LED REGISTER
    // ========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 16'd0;
        end
        else if (we && led_sel) begin
            case (funct3)

                // SB
                3'b000: begin
                    case (A[1:0])
                        2'b00:
                            led[7:0] <= wd[7:0];

                        2'b01:
                            led[15:8] <= wd[7:0];

                        default: ;
                    endcase
                end

                // SH
                3'b001: begin
                    if (A[1:0] == 2'b00)
                        led <= wd[15:0];
                end

                // SW
                3'b010: begin
                    if (A[1:0] == 2'b00)
                        led <= wd[15:0];
                end

                default: ;

            endcase
        end
    end


    // ========================================================
    // 10. RETURN DATA TO THE CPU
    // ========================================================

    always_comb begin
        RD = 32'd0;

        if (ram_sel) begin
            RD = ram_rd;
        end
        else if (
            led_sel ||
            sw_sel ||
            btn_sel ||
            uart_status_sel
        ) begin
            RD = mmio_rd_q;
        end
    end

endmodule