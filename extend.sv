// Extend unit -- zero-extends 12-bit value to 32 bits
module extendUnit(input  logic [11:0] imm12,
                  output logic [31:0] uimm32,
                  output logic [31:0] imm32);
  
  //assign imm32[20:0] = (imm32(11))imm12];
  assign uimm32[31:12] = 20'h00; //this math doesnt add up but it works
  assign uimm32[11:0] = imm12;
  
  assign imm32 = {{20{imm12[11]}}, imm12};
    
endmodule
