`timescale 1ns / 1ps
module mainfsm (
	clk,
	reset,
	Op,
	Funct,
	MulFunct,
	IRWrite,
	AdrSrc,
	ALUSrcA,
	ALUSrcB,
	ResultSrc,
	NextPC,
	RegW,
	MemW,
	Branch,
	ALUOp
);
	input wire clk;
	input wire reset;
	input wire [1:0] Op;
	input wire [5:0] Funct;
	input wire [3:0] MulFunct;
	output wire IRWrite;
	output wire AdrSrc;
	output wire [1:0] ALUSrcA;
	output wire [1:0] ALUSrcB;
	output wire [1:0] ResultSrc;
	output wire NextPC;
	output wire RegW;
	output wire MemW;
	output wire Branch;
	output wire ALUOp;
	reg [3:0] state;
	reg [3:0] nextstate;
	reg [12:0] controls;
  
	localparam [3:0] FETCH = 0;
	localparam [3:0] BRANCH = 9;
	localparam [3:0] DECODE = 1;
	localparam [3:0] EXECUTEI = 7;
	localparam [3:0] EXECUTER = 6;
	localparam [3:0] MEMADR = 2;
	localparam [3:0] UNKNOWN = 10;
  
	localparam [3:0] ALUWB=8;
	localparam [3:0] MEMWR=5;
	localparam [3:0] MEMWB=4;
	localparam [3:0] MEMRD=3;
	localparam [3:0] EXECUTEMUL = 11;  // Nuevo estado para la multiplicación

	// state register
	always @(posedge clk or posedge reset)
		if (reset)
			state <= FETCH;
		else
			state <= nextstate;

	// next state logic
	always @(*)
		casex (state)
			FETCH: nextstate = DECODE;
			DECODE:
				case (Op)
					2'b00:
						if (Funct[5:4] == 2'b00 && MulFunct == 4'b1001)  // MUL
							nextstate = EXECUTEMUL;
						else if (Funct[5] == 1'b1)
							nextstate = EXECUTEI;
						else
							nextstate = EXECUTER;
					2'b01: nextstate = MEMADR;
					2'b10: nextstate = BRANCH;
					default: nextstate = UNKNOWN;
				endcase
			EXECUTER: nextstate = ALUWB;
			EXECUTEI: nextstate = ALUWB;
			EXECUTEMUL: nextstate = ALUWB;  // Después de ejecutar la multiplicación, pasar a ALUWB
			MEMADR:
				if (Funct[0])
					nextstate = MEMRD;
				else 
					nextstate = MEMWR;
			MEMRD: nextstate = MEMWB;
			default: nextstate = FETCH;
		endcase

	// control logic
	always @(*)
		case (state)
			FETCH: controls =  13'b1000101001100;
			DECODE: controls = 13'b0000001001100;
			EXECUTER: controls = 13'b0000000000001;
			EXECUTEI: controls = 13'b0000000000011; 
			EXECUTEMUL: controls = 13'b0001000000001;  // Configuración de control para MUL
			ALUWB: controls = 13'b0001000000000;
			MEMADR: controls = 13'b0000000000010;
			MEMWR: controls = 13'b0010010000000;
			MEMRD: controls = 13'b0000010000000;
			MEMWB: controls = 13'b0001000100000;
			BRANCH: controls = 13'b0100001000010;
			default: controls = 13'bxxxxxxxxxxxxx;
		endcase

	assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule
