`timescale 1ns / 1ps

// Simulation-only Clock Wizard model.
// 200 MHz input -> 100 MHz output.
module clk_wiz_0 (
    input  wire clk_in1_p,
    input  wire clk_in1_n,
    input  wire reset,
    output logic clk_out1,
    output logic locked
);

    initial begin
        clk_out1 = 1'b0;
        locked   = 1'b0;
    end

    always @(posedge clk_in1_p or posedge reset) begin
        if (reset) begin
            clk_out1 <= 1'b0;
            locked   <= 1'b0;
        end else begin
            clk_out1 <= ~clk_out1;
            locked   <= 1'b1;
        end
    end

endmodule
