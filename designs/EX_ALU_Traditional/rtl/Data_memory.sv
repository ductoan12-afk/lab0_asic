module Instruction_memory(
    input logic [31:0] a,
    output logic [31:0] rd
);

    logic [31:0] ROM [16383:0];

    initial begin
        $display("[IMEM] Loading memfile.dat");
        $readmemh("memfile.dat", ROM);
    end

    assign rd = ROM[a[31:2]];

endmodule