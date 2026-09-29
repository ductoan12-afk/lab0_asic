.option norelax
.section .text
.globl _start
_start:
  lui x20,0x83000
  addi x1,x0,1
  addi x2,x0,2
  addi x3,x0,3
  addi x4,x0,4
  addi x5,x0,5
  addi x6,x0,6
  addi x7,x0,7
  addi x8,x0,8
  addi x9,x0,9
  addi x10,x0,10
  addi x11,x0,11
  addi x12,x0,12
  addi x13,x0,13
  addi x14,x0,14
  addi x15,x0,15
  addi x16,x0,16
  addi x17,x0,17
  addi x18,x0,18
  addi x19,x0,19
  addi x21,x0,21
  addi x22,x0,22
  addi x23,x0,23
  addi x24,x0,24
  addi x25,x0,25
  addi x26,x0,26
  sw x8,0(x20)
  sw x9,4(x20)
  sw x10,8(x20)
  sw x11,12(x20)
  sw x12,16(x20)
  sw x13,20(x20)
  sw x14,24(x20)
  sw x15,28(x20)
  lui x29,0x2
  addi x29,x29,1808
  addi x30,x0,0
  addi x31,x0,0

.Lloop:
  addi x29,x29,-1
  beq x29,x0,.Lfinish
  andi x28,x29,7
  beq x28,x0,.LB0
  beq x28,x1,.LB1
  beq x28,x2,.LB2
  beq x28,x3,.LB3
  beq x28,x4,.LB4
  beq x28,x5,.LB5
  beq x28,x6,.LB6
  jal x0,.LB7

.LB0:
  xori x9,x14,739
  xor x21,x11,x22
  slti x23,x26,1936
  sltu x24,x12,x19
  or x19,x16,x18
  srli x14,x23,14
  addi x26,x11,-459
  and x13,x13,x17
  xori x25,x9,-1417
  sw x8,248(x20)
  sltu x12,x17,x19
  srl x16,x11,x22
  beq  x1,x1,.LBR0_0
.LBR0_0:
  bne  x1,x1,.LBR0_1
.LBR0_1:
  blt  x0,x1,.LBR0_2
.LBR0_2:
  bge  x1,x0,.LBR0_3
.LBR0_3:
  bltu x0,x1,.LBR0_4
.LBR0_4:
  bgeu x1,x0,.LBR0_5
.LBR0_5:
  jal x0,.Lloop

.LB1:
  sltu x15,x24,x15
  or x23,x16,x12
  sltu x21,x14,x12
  sra x25,x13,x16
  addi x21,x13,21
  slt x14,x11,x8
  lw x26,60(x20)
  xor x11,x10,x23
  sw x25,172(x20)
  slti x25,x25,313
  lbu x12,177(x20)
  ori x22,x12,-2021
  beq  x1,x1,.LBR1_0
.LBR1_0:
  bne  x1,x1,.LBR1_1
.LBR1_1:
  blt  x0,x1,.LBR1_2
.LBR1_2:
  bge  x1,x0,.LBR1_3
.LBR1_3:
  bltu x0,x1,.LBR1_4
.LBR1_4:
  bgeu x1,x0,.LBR1_5
.LBR1_5:
  jal x0,.Lloop

.LB2:
  srli x10,x18,7
  sub x10,x13,x26
  ori x13,x14,1236
  addi x19,x23,-1828
  sw x9,204(x20)
  sra x19,x23,x13
  add x11,x17,x25
  sw x15,172(x20)
  addi x9,x23,1245
  sltu x18,x19,x21
  slli x26,x8,25
  sub x13,x24,x14
  beq  x1,x1,.LBR2_0
.LBR2_0:
  bne  x1,x1,.LBR2_1
.LBR2_1:
  blt  x0,x1,.LBR2_2
.LBR2_2:
  bge  x1,x0,.LBR2_3
.LBR2_3:
  bltu x0,x1,.LBR2_4
.LBR2_4:
  bgeu x1,x0,.LBR2_5
.LBR2_5:
  jal x0,.Lloop

.LB3:
  sb x13,74(x20)
  sb x17,96(x20)
  or x17,x21,x10
  srai x21,x10,10
  srai x24,x26,2
  andi x18,x16,-1356
  sll x9,x13,x14
  lh x14,52(x20)
  xori x14,x16,642
  and x8,x18,x21
  sub x24,x17,x14
  sub x10,x18,x19
  beq  x1,x1,.LBR3_0
.LBR3_0:
  bne  x1,x1,.LBR3_1
.LBR3_1:
  blt  x0,x1,.LBR3_2
.LBR3_2:
  bge  x1,x0,.LBR3_3
.LBR3_3:
  bltu x0,x1,.LBR3_4
.LBR3_4:
  bgeu x1,x0,.LBR3_5
.LBR3_5:
  jal x0,.Lloop

.LB4:
  srli x14,x15,2
  lhu x13,222(x20)
  addi x10,x12,1632
  and x15,x12,x12
  slt x17,x11,x8
  add x21,x18,x17
  addi x8,x26,1168
  lhu x11,240(x20)
  lb x23,95(x20)
  add x21,x9,x23
  andi x23,x24,-1156
  srl x11,x22,x16
  beq  x1,x1,.LBR4_0
.LBR4_0:
  bne  x1,x1,.LBR4_1
.LBR4_1:
  blt  x0,x1,.LBR4_2
.LBR4_2:
  bge  x1,x0,.LBR4_3
.LBR4_3:
  bltu x0,x1,.LBR4_4
.LBR4_4:
  bgeu x1,x0,.LBR4_5
.LBR4_5:
  jal x0,.Lloop

.LB5:
  slti x14,x22,-1251
  xori x18,x26,961
  and x22,x21,x19
  addi x25,x12,-85
  lh x23,246(x20)
  xori x19,x17,18
  lh x25,146(x20)
  lh x23,88(x20)
  slti x26,x9,1634
  addi x9,x22,1932
  lb x12,57(x20)
  xori x25,x13,1575
  beq  x1,x1,.LBR5_0
.LBR5_0:
  bne  x1,x1,.LBR5_1
.LBR5_1:
  blt  x0,x1,.LBR5_2
.LBR5_2:
  bge  x1,x0,.LBR5_3
.LBR5_3:
  bltu x0,x1,.LBR5_4
.LBR5_4:
  bgeu x1,x0,.LBR5_5
.LBR5_5:
  jal x0,.Lloop

.LB6:
  sw x21,72(x20)
  lbu x19,9(x20)
  sltiu x10,x9,1922
  add x14,x14,x15
  slt x8,x22,x11
  sb x16,146(x20)
  sltiu x23,x18,-1771
  sub x9,x26,x16
  lbu x21,222(x20)
  and x23,x25,x10
  sltiu x22,x26,414
  and x23,x21,x10
  beq  x1,x1,.LBR6_0
.LBR6_0:
  bne  x1,x1,.LBR6_1
.LBR6_1:
  blt  x0,x1,.LBR6_2
.LBR6_2:
  bge  x1,x0,.LBR6_3
.LBR6_3:
  bltu x0,x1,.LBR6_4
.LBR6_4:
  bgeu x1,x0,.LBR6_5
.LBR6_5:
  jal x0,.Lloop

.LB7:
  slti x21,x23,329
  andi x19,x9,-299
  xor x24,x9,x9
  add x11,x12,x15
  lw x22,52(x20)
  add x23,x10,x10
  srli x18,x26,20
  ori x23,x21,-1469
  and x10,x15,x21
  srl x11,x18,x21
  sub x23,x23,x21
  and x18,x22,x23
  beq  x1,x1,.LBR7_0
.LBR7_0:
  bne  x1,x1,.LBR7_1
.LBR7_1:
  blt  x0,x1,.LBR7_2
.LBR7_2:
  bge  x1,x0,.LBR7_3
.LBR7_3:
  bltu x0,x1,.LBR7_4
.LBR7_4:
  bgeu x1,x0,.LBR7_5
.LBR7_5:
  jal x0,.Lloop

.Lfinish:
  add x31,x1,x0
  add x30,x2,x0
  slli x31,x31,5
  xor x31,x31,x2
  slli x30,x30,7
  xor x30,x30,x2
  slli x31,x31,5
  xor x31,x31,x3
  slli x30,x30,7
  xor x30,x30,x3
  slli x31,x31,5
  xor x31,x31,x4
  slli x30,x30,7
  xor x30,x30,x4
  slli x31,x31,5
  xor x31,x31,x5
  slli x30,x30,7
  xor x30,x30,x5
  slli x31,x31,5
  xor x31,x31,x6
  slli x30,x30,7
  xor x30,x30,x6
  slli x31,x31,5
  xor x31,x31,x7
  slli x30,x30,7
  xor x30,x30,x7
  slli x31,x31,5
  xor x31,x31,x8
  slli x30,x30,7
  xor x30,x30,x8
  slli x31,x31,5
  xor x31,x31,x9
  slli x30,x30,7
  xor x30,x30,x9
  slli x31,x31,5
  xor x31,x31,x10
  slli x30,x30,7
  xor x30,x30,x10
  slli x31,x31,5
  xor x31,x31,x11
  slli x30,x30,7
  xor x30,x30,x11
  slli x31,x31,5
  xor x31,x31,x12
  slli x30,x30,7
  xor x30,x30,x12
  slli x31,x31,5
  xor x31,x31,x13
  slli x30,x30,7
  xor x30,x30,x13
  slli x31,x31,5
  xor x31,x31,x14
  slli x30,x30,7
  xor x30,x30,x14
  slli x31,x31,5
  xor x31,x31,x15
  slli x30,x30,7
  xor x30,x30,x15
  slli x31,x31,5
  xor x31,x31,x16
  slli x30,x30,7
  xor x30,x30,x16
  slli x31,x31,5
  xor x31,x31,x17
  slli x30,x30,7
  xor x30,x30,x17
  slli x31,x31,5
  xor x31,x31,x18
  slli x30,x30,7
  xor x30,x30,x18
  slli x31,x31,5
  xor x31,x31,x19
  slli x30,x30,7
  xor x30,x30,x19
  slli x31,x31,5
  xor x31,x31,x21
  slli x30,x30,7
  xor x30,x30,x21
  slli x31,x31,5
  xor x31,x31,x22
  slli x30,x30,7
  xor x30,x30,x22
  slli x31,x31,5
  xor x31,x31,x23
  slli x30,x30,7
  xor x30,x30,x23
  slli x31,x31,5
  xor x31,x31,x24
  slli x30,x30,7
  xor x30,x30,x24
  slli x31,x31,5
  xor x31,x31,x25
  slli x30,x30,7
  xor x30,x30,x25
  slli x31,x31,5
  xor x31,x31,x26
  slli x30,x30,7
  xor x30,x30,x26
  slli x31,x31,5
  xor x31,x31,x27
  slli x30,x30,7
  xor x30,x30,x27
  slli x31,x31,5
  xor x31,x31,x28
  slli x30,x30,7
  xor x30,x30,x28
  slli x31,x31,5
  xor x31,x31,x29
  slli x30,x30,7
  xor x30,x30,x29
  sw x31,1792(x20)
  sw x30,1796(x20)
.Lhalt:
  jal x0,.Lhalt
