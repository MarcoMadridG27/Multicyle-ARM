`timescale 1ns / 1ps
module datapath (
	clk,
	reset,
	Adr,
	WriteData,
	ReadData,
	Instr,
	ALUFlags,
	PCWrite,
	RegWrite,
	IRWrite,
	AdrSrc,
	RegSrc,
	ALUSrcA,
	ALUSrcB,
	ResultSrc,
	ImmSrc,
	ALUControl
);
	input wire clk;
	input wire reset;
	output wire [31:0] Adr;
	output wire [31:0] WriteData;
	input wire [31:0] ReadData;
	output wire [31:0] Instr;
	output wire [3:0] ALUFlags;
	input wire PCWrite;
	input wire RegWrite;
	input wire IRWrite;
	input wire AdrSrc;
	input wire [1:0] RegSrc;
	input wire [1:0] ALUSrcA;
	input wire [1:0] ALUSrcB;
	input wire [1:0] ResultSrc;
	input wire [1:0] ImmSrc;
	input wire [2:0] ALUControl;
	wire [31:0] PCNext;
	wire [31:0] PC;
	wire [31:0] ExtImm;
	wire [31:0] SrcA;
	wire [31:0] SrcB;
	wire [31:0] Result;
	wire [31:0] Data;
	wire [31:0] RD1;
	wire [31:0] RD2;
	wire [31:0] A;
	wire [31:0] ALUResult;
	wire [31:0] ALUOut;
	wire [3:0] RA1;
	wire [3:0] RA2;
	wire [3:0] WA3;
	wire [3:0] RA1_sel;
	wire [3:0] RA2_sel;
	
	wire is_mul;
    assign is_mul = (Instr[27:22] == 6'b000000) && (Instr[7:4] == 4'b1001);
    
	flopenr #(32) pcreg(.clk(clk),.reset(reset),.en(PCWrite),.d(PCNext),.q(PC));
	mux2 #(32) pcmux(.d0(PC), .d1(Result), .s(AdrSrc),.y(Adr));
	
	flopenr #(32) rdreg(.clk(clk),.reset(reset),.en(IRWrite),.d(ReadData),.q(Instr));

	flopr #(32) datareg(
		.clk(clk),
		.reset(reset),
		.d(ReadData),
		.q(Data)
	);
	
    mux2 #(4) ra1mux(
        .d0(is_mul ? Instr[3:0] : Instr[19:16]),  // Rn (para MUL) vs Rn estándar
        .d1(4'b1111),
        .s(RegSrc[0]),
        .y(RA1)
    );

    mux2 #(4) ra2mux(
        .d0(is_mul ? Instr[11:8] : Instr[3:0]),   // Rm (para MUL) vs Rm estándar
        .d1(Instr[15:12]),
        .s(RegSrc[1]),
        .y(RA2)
    );

    regfile rf(
        .clk(clk),
        .we3(RegWrite),
        .ra1(RA1),
        .ra2(RA2),
        .wa3(is_mul ? Instr[19:16] : Instr[15:12]),
        .wd3(Result),
        .r15(Result),
        .rd1(RD1),
        .rd2(RD2)
    );

	
	extend ext(
		.Instr(Instr[23:0]),
		.ImmSrc(ImmSrc),
		.ExtImm(ExtImm)
	);
	
	flopr2 #(32) datareg2(
		.clk(clk),
		.reset(reset),
		.d1(RD1),
		.d2(RD2),
		.q1(A),
		.q2(WriteData)
	);

	mux2 #(32) Srcmux(
		.d0(A),
		.d1(PC),
		.s(ALUSrcA[0]),
		.y(SrcA)
	);
	
	mux3 #(32) Srcbmux (
		.d0(WriteData),
		.d1(ExtImm),
		.d2(32'b100),
		.s(ALUSrcB),
		.y(SrcB));
	alu alu(
		SrcA,
		SrcB,
		ALUControl,
		ALUResult,
		ALUFlags
	);
	flopr #(32) aluR(
		.clk(clk),
		.reset(reset),
		.d(ALUResult),
		.q(ALUOut)
	);
	mux3 #(32) AluOutMux (
		.d0(ALUOut),
		.d1(Data),
		.d2(ALUResult),
		.s(ResultSrc),
		.y(Result));
	assign PCNext = Result;
endmodule