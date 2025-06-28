`timescale 1ns / 1ps
module decode (
    clk,
    reset,
    Op,
    Funct,
    MulFunct,
    Rd,
    FlagW,
    PCS,
    NextPC,
    RegW,
    MemW,
    IRWrite,
    AdrSrc,
    ResultSrc,
    ALUSrcA,
    ALUSrcB,
    ImmSrc,
    RegSrc,
    ALUControl
);
    input wire clk;
    input wire reset;
    input wire [1:0] Op;
    input wire [5:0] Funct;
    input wire [3:0] MulFunct;
    input wire [3:0] Rd;
    output reg [1:0] FlagW;
    output wire PCS;
    output wire NextPC;
    output wire RegW;
    output wire MemW;
    output wire IRWrite;
    output wire AdrSrc;
    output wire [1:0] ResultSrc;
    output wire [1:0] ALUSrcA;
    output wire [1:0] ALUSrcB;
    output wire [1:0] ImmSrc;
    output wire [1:0] RegSrc;
    output reg [2:0] ALUControl;
    wire Branch;
    wire ALUOp;

    // Main FSM
    mainfsm fsm (
        .clk(clk),
        .reset(reset),
        .Op(Op),
        .Funct(Funct),
        .MulFunct(MulFunct),
        .IRWrite(IRWrite),
        .AdrSrc(AdrSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .NextPC(NextPC),
        .RegW(RegW),
        .MemW(MemW),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );

    // ALU Decoder
    always @(*) begin
        if (ALUOp) begin
            // MUL: Op=00, Funct[5:4]=00, MulFunct[3:0]=1001 (bits 7:4 de la instrucción)
            if (Funct[5:4] == 2'b00 && MulFunct[3:0] == 4'b1001) begin
                ALUControl = 3'b110;
                FlagW[1] = Funct[0]; // S bit
                FlagW[0] = 1'b0;     // No actualiza C y V
            end else begin
                case (Funct[4:1])
                    4'b0000: ALUControl = 3'b010; // AND
                    4'b0001: ALUControl = 3'b100; // XOR
                    4'b0010: ALUControl = 3'b001; // SUB
                    4'b0100: ALUControl = 3'b000; // ADD
                    4'b0101: ALUControl = 3'b000; // ADC
                    4'b1000: ALUControl = 3'b010; // TST
                    4'b1011: ALUControl = 3'b000; // CMN
                    4'b1100: ALUControl = 3'b011; // ORR
                    default: ALUControl = 3'bxxx;
                endcase

                // Update FlagW for instructions that affect flags (S bit = 1)
                FlagW[1] = Funct[0]; // S bit
                case (Funct[4:1])
                    4'b0100, 4'b0010, 4'b1010, 4'b1011:
                        FlagW[0] = Funct[0]; // Actualiza C y V si S = 1
                    default:
                        FlagW[0] = 1'b0;
                endcase
            end
        end else begin
            ALUControl = 3'b000;
            FlagW = 2'b00;
        end
    end

    // PC Logic
    assign PCS = ((Rd == 4'b1111) & RegW) | Branch;

    // Instr Decoder
    assign ImmSrc = Op;
    assign RegSrc[0] = (Op == 2'b10);
    assign RegSrc[1] = (Op == 2'b01); 

endmodule
