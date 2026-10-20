`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 10:10:02 AM
// Design Name: Nguyen Duc Toan
// Module Name: UART_RX
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

module UART_RX #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE = 115200
    )(
    input logic clk,
    input logic reset,
    input logic rx,  // nhan tung bit 1, du 8 bit/ 1byte thi truyen 1 luc
    output logic [7:0] rx_data,
    output logic rx_valid,  // xac nhan nhan du 1 byte de ra tin hieu truyen di
    output logic framing_error, // check loi bit STOP khac 1, STOP phai la 1
    output logic busy
    );
    
    localparam integer CLKs_PER_BIT = (CLOCK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;
    localparam integer HALF_BIT = (CLKs_PER_BIT > 1) ? (CLKs_PER_BIT / 2) : 1; // de CPU doc tin hieu bit nhan duoc o giua bit, tranh nhan o dau or cuoi bit truyen
    localparam integer COUNT_WIDTH = (CLKs_PER_BIT > 1) ? $clog2(CLKs_PER_BIT) : 1;  // dem so bit can de ma hoa 
    
    localparam logic [1:0] idle = 2'b00;
    localparam logic [1:0] start_bit = 2'b01;
    localparam logic [1:0] data_bit = 2'b10;
    localparam logic [1:0] stop_bit = 2'b11;
    logic [1:0] state = idle;
    
    logic [COUNT_WIDTH-1:0] clk_count;
    logic [2:0] bit_index; // dem so bit dang nhan
    logic [7:0] shift_reg;
    
    logic rx_sync1;
    logic rx_sync2;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end
        else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end
    
    
    assign busy = (state != idle);
    
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= idle;
            clk_count <= '0;
            bit_index <= 3'd0;
            shift_reg <= 8'd0;
            rx_data <= 8'd0;
            rx_valid <= 1'd0;
            framing_error <= 1'd0;
        end
        else begin // mac dinh 2 tin hieu nay khong bat, tru khi xay ra truong hop cu the moi bat
            rx_valid <= 1'd0;
            framing_error <= 1'd0;
            
            
            case(state)
            
                idle: begin
                    clk_count <= '0;// neu khong xac dinh duoc so bit cua tin hieu thi dung '0 khi bit nay la 0
                    bit_index <= 3'd0;
                    if(rx_sync2 == 1'd0) begin
                        state <= start_bit;
                        clk_count <= '0;
                    end
                end
                start_bit: begin
                    if(clk_count == HALF_BIT -1) begin
                        clk_count <= '0;
                        if(rx_sync2 == 1'd0) begin
                            state <= data_bit; // neu tin hieu o giua bit start la 0 thi bit start nay dung
                            bit_index <= 3'd0;
                        end
                        else begin
                            state <= idle; // neu giua bit van la 1 thi nay la bit nhieu,loi
                        end
                    end
                    else begin
                    clk_count <= clk_count + 1'b1;               
                    end   
                end
                data_bit: begin
                    if(clk_count == CLKs_PER_BIT - 1) begin
                        clk_count <= '0;
                        shift_reg[bit_index] <= rx_sync2; // khi het du 1 bit thi no nhap vao temp
                        if(bit_index == 3'd7) begin // neu du 8 bit/ 1byte
                            state <= stop_bit;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                stop_bit: begin
                    if(clk_count == CLKs_PER_BIT - 1) begin
                        clk_count <= '0;
                        state <= idle;
                        if(rx_sync2 == 1'b1) begin
                            rx_data <= shift_reg;
                            rx_valid <= 1'b1;
                        end
                        else begin
                            framing_error <= 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
                
                default: begin
                    state <= idle;
                    clk_count <= '0;
                    bit_index <= 3'd0;
                    shift_reg <= 8'd0;
                end
            endcase
         end
     end 
endmodule
