// Control unit for the VMI CPU
module controlUnit(
  input  logic [7:0] opcode,
  output logic       regWrite,
  output logic       aluSrcA,
  output logic       aluSrcB,
  output logic [1:0] aluControl,
  output logic       memWrite,
  output logic [1:0] resultSrc,
  output logic       Branch,
  output logic       BranchEQ,
  output logic       BranchNE,
  output logic       BranchReg
);

  // Opcodes
  localparam NOP   = 8'h00,
  			 ADD_R = 8'h01,
             ADD_I = 8'h02,
             SUB_R = 8'h03,
             SUB_I = 8'h04,
             AND_R = 8'h05,
             AND_I = 8'h06,
             OR_R  = 8'h07,
             OR_I  = 8'h08,
             MOV_R = 8'h09,
             MOV_I = 8'h0a,
             LDR   = 8'h0b,
             STR   = 8'h0c,
             B     = 8'h0d,
             BEQ   = 8'h0e,
             BNE   = 8'h0f,
             BL    = 8'h10,
             BRN   = 8'h11;

  // Control vector: 12 bits total
  //2 new bc result becomes 2 bit and reg is added
  logic [11:0] controls;

  assign {regWrite, aluSrcA, aluSrcB, aluControl, resultSrc, memWrite,
          Branch, BranchEQ, BranchNE, BranchReg} = controls;
//came back to fix this way after it was due and now everythhing works
  always_comb begin
    unique case (opcode)
      NOP  : controls = 12'b0_0_0_00_00_0_0_0_0_0;
      ADD_R: controls = 12'b1_0_0_00_00_0_0_0_0_0; 
      ADD_I: controls = 12'b1_0_1_00_00_0_0_0_0_0;
      SUB_R: controls = 12'b1_0_0_01_00_0_0_0_0_0;
      SUB_I: controls = 12'b1_0_1_01_00_0_0_0_0_0;
      AND_R: controls = 12'b1_0_0_10_00_0_0_0_0_0;
      AND_I: controls = 12'b1_0_1_10_00_0_0_0_0_0;
      OR_R : controls = 12'b1_0_0_11_00_0_0_0_0_0;
      OR_I : controls = 12'b1_0_1_11_00_0_0_0_0_0;
      MOV_R: controls = 12'b1_1_0_00_00_0_0_0_0_0;
      MOV_I: controls = 12'b1_1_1_00_00_0_0_0_0_0;
      LDR  : controls = 12'b1_0_1_00_01_0_0_0_0_0; // load resultSrc=01
      STR  : controls = 12'b0_0_1_00_00_1_0_0_0_0; // store memWrite=1
      B    : controls = 12'b0_0_0_00_00_0_1_0_0_0; // branch
      BEQ  : controls = 12'b0_0_0_01_00_0_0_1_0_0; // branch eq
      BNE  : controls = 12'b0_0_0_01_00_0_0_0_1_0; // branch ne
      BL   : controls = 12'b1_0_0_00_10_0_1_0_0_0; // branch + link
      BRN  : controls = 12'b0_0_0_00_00_0_0_0_0_1; // branch reg
      default: controls = 12'b0_0_0_00_00_0_0_0_0_0;
    endcase
  end
endmodule
