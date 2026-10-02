# scripts/setup.tcl
set PROJ [file normalize [file dirname [info script]]/..]
set PDK  $PROJ/pdk/nangate45

set LIB_SLOW $PDK/lib/NangateOpenCellLibrary_typical.lib
set LIB_FAST $PDK/lib/NangateOpenCellLibrary_typical.lib

set TECH_LEF $PDK/lef/NangateOpenCellLibrary.tech.lef
set CELL_LEF $PDK/lef/NangateOpenCellLibrary.macro.lef

set DESIGN   rv32i_core
set RTL_FILES [list \
    $PROJ/rtl/rv32i_pkg.sv \
    $PROJ/rtl/rv32i_alu.sv \
    $PROJ/rtl/rv32i_regfile.sv \
    $PROJ/rtl/rv32i_imm_gen.sv \
    $PROJ/rtl/rv32i_decoder.sv \
    $PROJ/rtl/rv32i_branch_unit.sv \
    $PROJ/rtl/rv32i_hazard.sv \
    $PROJ/rtl/rv32i_lsu.sv \
    $PROJ/rtl/rv32i_core.sv \
]

set CLK_PORT clk_i
set CLK_PERIOD 2.5
