`timescale 1ns / 1ps
module condlogic (
clk,
reset,
Cond,
ALUFlags,
FlagW,
PCS,
NextPC,
RegW,
MemW,
PCWrite,
RegWrite,
MemWrite
);
input wire clk;
input wire reset;
input wire [3:0] Cond;
input wire [3:0] ALUFlags;
input wire [1:0] FlagW;
input wire PCS;
input wire NextPC;
input wire RegW;
input wire MemW;
output wire PCWrite;
output wire RegWrite;
output wire MemWrite;
wire [1:0] FlagWrite;
wire [3:0] Flags;
wire CondEx;
wire CondEx_reg;

// Flags register
flopenr #(2) flagreg1(
.clk(clk),
.reset(reset),
.en(FlagWrite[1]),
.d(ALUFlags[3:2]),
.q(Flags[3:2])
);
flopenr #(2) flagreg0(
.clk(clk),
.reset(reset),
.en(FlagWrite[0]),
.d(ALUFlags[1:0]),
.q(Flags[1:0])
);

// Evaluación de condición
condcheck cc(
.Cond(Cond),
.Flags(Flags),
.CondEx(CondEx)
);
flopr #(1) condExReg(
        .clk(clk),
        .reset(reset),
  		.d(CondEx),
  		.q(CondEx_reg)
        );

// Aplicación de CondEx a las señales de escritura
assign FlagWrite=FlagW &{2{CondEx}};  
assign RegWrite  = RegW  & CondEx_reg;
assign MemWrite  = MemW  & CondEx_reg;
 //assign PCSrc = PCS & CondEx_reg;
  assign PCWrite   = (PCS | NextPC) & CondEx_reg;

endmodule
