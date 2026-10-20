`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2026 11:24:02 AM
// Design Name: Nguyen Duc Toan
// Module Name: Hazard_Unit
// Project Name: RV32I
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


module Hazard_Unit( 
    // Input dau vao (kiem tra)
    input logic [4:0] Rs1D,Rs2D,
    input logic [4:0] Rs1E,Rs2E,
    input logic [4:0] RdE,RdM,RdW,
    input logic regwriteM,regwriteW,
    input logic [1:0] result_srcE,
    input logic PCsrcE,
    
    // Output dau ra (thuc thi)
    output logic StallF,StallD,
    output logic FlushD,FlushE,
    output logic [1:0] ForwardA,ForwardB
    );
    logic lwstall; // stall o lenh lw
    // Loi Forwarding ALU
    // uu tien MEM stage
    always_comb begin  // input1 vao ALU
        if(regwriteM && RdM != 5'd0 && (RdM == Rs1E)) begin
            ForwardA = 2'b10;
        end
        else if(regwriteW && RdW != 5'd0 && (RdW == Rs1E)) begin
            ForwardA = 2'b01;
        end
        else begin
            ForwardA = 2'b00;
        end
    end
    
    // input2 vao ALU
    always_comb begin 
        if(regwriteM && RdM != 5'd0 && (RdM == Rs2E)) begin
            ForwardB = 2'b10;
        end
        else if(regwriteW && RdW != 5'd0 && (RdW == Rs2E)) begin
            ForwardB = 2'b01;
        end
        else begin
            ForwardB = 2'b00;
        end
    end
    // xu li loi load-use hazard
// Phép so sánh === s? tr? v? 0 (False) n?u result_srcE[0] là 'x', không b? lan truy?n 'x'
    assign lwstall = (result_srcE[0] === 1'b1) && (RdE != 5'd0) && ((RdE == Rs1D) || (RdE == Rs2D));
    assign StallD = lwstall;
    assign StallF = lwstall;
    
    // xu li loi control hazard
    assign FlushD = PCsrcE;
    assign FlushE = lwstall || PCsrcE;
    
endmodule
