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
    input logic regwriteM,regwriteW,regwriteE,
    input logic [1:0] result_srcE,
    input logic branchD,
    input logic PCsrcE, // do lenh JAL/JALR van duoc xu li tai EX
    input logic PCsrcD,
    
    // Output dau ra (thuc thi)
    output logic StallF,StallD,
    output logic FlushD,FlushE,
    output logic [1:0] ForwardA,ForwardB, // forward tai EX
    output logic [1:0] ForwardA_D,ForwardB_D // forward tai ID
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
    
    // Xu li hazard tai ID MUX 4:1 RD1
    always_comb begin
        ForwardA_D = 2'b00;
        if(branchD && (Rs1D != 5'd0)) begin
            if(regwriteE && (RdE != 5'd0) && (RdE == Rs1D)) begin
                if(result_srcE[0] === 1'b0)  // khong phai lenh load
                    ForwardA_D = 2'b11; // forward EX
                else
                    ForwardA_D = 2'b00;              
            end
        else if( regwriteM && (RdM != 5'd0) && (RdM == Rs1D)) begin
            ForwardA_D = 2'b10;  // forward MEM
        end
        else if(regwriteW && (RdW != 5'd0) && (RdW == Rs1D)) begin
            ForwardA_D = 2'b01; // forward WB
        end
    end
    end
    // ID RD2
    always_comb begin
        ForwardB_D = 2'b00;

        if (branchD && (Rs2D != 5'd0)) begin

            if (regwriteE &&
                (RdE != 5'd0) &&
                (RdE == Rs2D)) begin

                if (result_srcE[0] === 1'b0)
                    ForwardB_D = 2'b11;  // EX result available
                else
                    ForwardB_D = 2'b00;  // EX load: wait

            end
            else if (regwriteM &&
                     (RdM != 5'd0) &&
                     (RdM == Rs2D)) begin

                ForwardB_D = 2'b10;      // MEM

            end
            else if (regwriteW &&
                     (RdW != 5'd0) &&
                     (RdW == Rs2D)) begin

                ForwardB_D = 2'b01;      // WB
            end
        end
    end
    // xu li loi control hazard
    assign FlushD = PCsrcE || PCsrcD;
    assign FlushE = lwstall || PCsrcE || PCsrcD;
    
endmodule
