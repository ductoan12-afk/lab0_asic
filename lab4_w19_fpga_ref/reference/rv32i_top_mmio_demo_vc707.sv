`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 10:09:26 AM
// Design Name: Nguyen Duc Toan
// Module Name: rv32i_top_mmio_demo_vc707
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


module rv32i_top_mmio_demo_vc707 (
    // VC707 system clock: 200 MHz differential
    input  logic       sysclk_p,
    input  logic       sysclk_n,

    // Dedicated CPU reset pushbutton: SW8
    input  logic       cpu_reset,

    // VC707: 8 DIP switches
    input  logic [7:0] gpio_dip_sw,

    // Four directional user pushbuttons
    input  logic       gpio_btn_n,
    input  logic       gpio_btn_e,
    input  logic       gpio_btn_s,
    input  logic       gpio_btn_w,

    // VC707: 8 user LEDs
    input  logic       uart_rx,
    output logic [7:0] gpio_led,
    output logic       uart_tx
);

    // Internal interface retained from the tested design
    logic [15:0] sw_internal;
    logic [3:0]  btn_internal;
    logic [15:0] led_internal;

    // The physical board has only 8 DIP switches.
    // The upper 8 switch bits are tied to zero.
    assign sw_internal = {8'h00, gpio_dip_sw};

    // Preserve the existing 4-bit button interface:
    // btn[0] = North
    // btn[1] = East
    // btn[2] = South
    // btn[3] = West
    assign btn_internal = {
        gpio_btn_w,
        gpio_btn_s,
        gpio_btn_e,
        gpio_btn_n
    };

    // The physical board has only 8 user LEDs.
    assign gpio_led = led_internal[7:0];

    // Reuse the existing design without changing CPU logic.
    rv32i_top_mmio_demo u_cpu_demo (
        .clk_p (sysclk_p),
        .clk_n (sysclk_n),
        .reset (cpu_reset),
        .sw    (sw_internal),
        .btn   (btn_internal),
        .uart_rx (uart_rx),
        .led   (led_internal),
        .uart_tx (uart_tx)
    );

endmodule
