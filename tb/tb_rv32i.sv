`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2026 10:15:37 PM
// Design Name: 
// Module Name: tb_rv32i
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


module tb_rv32i;
    reg clk;
    reg rst;

    // Kh?i t?o module chính c?a chip
    rv32i_top u_top (
        .clk(clk),
        .reset(rst)
    );

    // T?o xung nh?p clock (chu k? 10ns)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #20;
        rst = 0; // Th? reset sau 20ns

        // B? ??m th?i gian t?i ?a (Watchdog) tránh ch?y l?p vô t?n
        #500000;
        $display("[TB] TIMEOUT: Ch??ng trình ch?y quá th?i gian gi?i h?n!");
        $finish;
    end

    // Theo dõi tín hi?u ghi d? li?u vào ??a ch? ToHost (0x1000)
    always @(posedge clk) begin
        // Ki?m tra n?u có tín hi?u ghi và ??a ch? là 0x1000
        // (Tên tín hi?u bên d??i có th? thay ??i tùy theo thi?t k? c?a b?n)
        if (u_top.Data_memory_unit.we && (u_top.Data_memory_unit.A == 32'h00001000)) begin
            if (u_top.Data_memory_unit.wd == 32'h00000001) begin
                $display("[TB] ===== TEST PASSED ===== (Mã k?t qu?: PASS)");
                #50;
                $finish;
            end else begin
                $display("[TB] ===== TEST FAILED ===== (Mã l?i: %0d)", u_top.Data_memory_unit.wd);
                #50;
                $finish;
            end
        end
    end

endmodule
