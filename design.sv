// Top-level design
//
//
`include "regfile.sv"
`include "alu.sv"
`include "util.sv"
`include "extend.sv"
`include "controlUnit.sv"
`include "memory.sv"
`include "hazardUnit.sv"

module cpu(input  logic        clk,
           input  logic        reset);
  
  //one time variables (no similar declarations)
  logic [7:0]opcode;
  logic [3:0]rn;
  logic [3:0]rm;
  logic [11:0]imm12;
  logic [31:0] pc, PCBranch, PCnext;
  logic [1:0] PCSrc;
  logic [31:0]srcA, srcB;
  logic [31:0]wd3;
  
  //pipeline variables
  logic [3:0]  rd_d, rd_e, rd_m, rd_w, rn_d, rm_d, rn_e, rm_e;
  logic [31:0] instr_f, instr_d;
  logic [31:0] imm32_d, imm32_e;
  logic [31:0] pcplus4_f, pcplus4_d, pcplus4_e, pcplus4_m, pcplus4_w;
  logic branchreg_d, branchreg_e;
  logic branch_d, branch_e;
  logic brancheq_d, brancheq_e;
  logic branchne_d, branchne_e;
  logic regwrite_d, regwrite_e;
  logic [1:0] resultsrc_d, resultsrc_e, alucontrol_d, alucontrol_e;
  logic memwrite_d, memwrite_e, memwrite_m;
  logic alusrca_d, alusrcb_d, alusrca_e, alusrcb_e;
  logic [31:0] rega_d, regb_d, rega_e, regb_e, regb_m;
  logic [31:0] imm_d, uimm_e, imm_e, uimm_d;
  logic [3:0] aluFlags;
  logic [31:0] aluresult_e, aluresult_m, aluresult_w;
  logic regwrite_m, regwrite_w;
  logic [1:0] resultsrc_m, resultsrc_w;
  logic [31:0] memresult_m, memresult_w;
  logic [31:0] rega_fwd, regb_fwd;
  //logic for hazard unit
  logic [1:0] forwardA, forwardB; 
  logic stall, Nstall;
  logic branchTaken, BranReset, exreset;
  
  //assignments for hazard unit outputs into cpu
  assign Nstall = ~stall;
  assign BranReset = (branchTaken || reset);
  assign exreset = (branchTaken || stall || reset);
  
  mux4 muxy3(.d0(pcplus4_f), .d1(PCBranch), .d2(rega_fwd), .d3(), .s(PCSrc), .y(PCnext)); //initial mux
  
  register_ren r(.clk(clk), .reset(reset), .en(Nstall), .d(PCnext), .q(pc)); //register module instantiation

  assign pcplus4_f = pc + 32'h4; //adder for the register module
  
  imem m(.addr(pc), .data(instr_f)); //memory module instantiation
  
  register_ren #(64) IFID(.clk(clk), .reset(BranReset), .en(Nstall),
                  .d({instr_f, pcplus4_f}),
                  .q({instr_d, pcplus4_d})); //reg for ifid
  
  //breaking the instr into pieces to be dispersed
  assign opcode = instr_d[31:24]; 
  assign rd_d 	= instr_d[23:20];
  assign rn_d	= instr_d[19:16];
  assign rm_d	= instr_d[15:12];
  assign imm12 	= instr_d[11:0];
  
  controlUnit cu(.opcode(opcode), .regWrite(regwrite_d), .aluSrcA(alusrca_d), .aluSrcB(alusrcb_d), .aluControl(alucontrol_d), .memWrite(memwrite_d), .resultSrc(resultsrc_d), .Branch(branch_d), .BranchEQ(brancheq_d), .BranchNE(branchne_d), .BranchReg(branchreg_d)); //instantiated connection to the control unit module
  
  regfile rf(.clk(clk), .reset(reset), .we3(regwrite_w), .wd3(wd3), .ra1(rn_d), .ra2(rm_d), .wa3(rd_w), .rd1(rega_d), .rd2(regb_d));//register file instantiation
  
  extendUnit extend 
  (.imm12(imm12), .uimm32(uimm_d), .imm32(imm32_d));  //extend unit instantiation
  
  register_r #(184) IDEX(.clk(clk), .reset(exreset),
                         .d({branchreg_d, branch_d, brancheq_d, branchne_d, regwrite_d, resultsrc_d, memwrite_d, alucontrol_d, alusrca_d, alusrcb_d, rega_d, regb_d, uimm_d, imm32_d, pcplus4_d, rd_d, rn_d, rm_d}),
                     .q({branchreg_e, branch_e, brancheq_e, branchne_e, regwrite_e, resultsrc_e, memwrite_e, alucontrol_e, alusrca_e, alusrcb_e, rega_e, regb_e, uimm_e, imm32_e, pcplus4_e, rd_e, rn_e, rm_e})); //large idex instantiation
  
  assign PCSrc = {branchreg_e,(branch_e || (brancheq_e && aluFlags[2]) || (branchne_e && ~aluFlags[2]))}; //top level logic with added branchreg to pcsrc
  
  mux4 muxy5(.d0(rega_e), .d1(wd3), .d2(aluresult_m), .d3(), .s(forwardA), .y(rega_fwd)); //fwd mux a
  
  mux4 muxy6(.d0(regb_e), .d1(wd3), .d2(aluresult_m), .d3(), .s(forwardB), .y(regb_fwd)); //fwd mux b
  
  mux2 muxy1
  (.d0(rega_fwd), .d1(32'b0), .s(alusrca_e), .y(srcA)); //srca mux
  
  mux2 muxy2
  (.d0(regb_fwd), .d1(uimm_e), .s(alusrcb_e), .y(srcB)); //srcb mux
  
  assign PCBranch = pcplus4_e + {imm32_e[29:0], 2'b00}; //sent back to initial mux
  
  ALU send(.a(srcA), .b(srcB), .f(alucontrol_e), .flags(aluFlags), .result(aluresult_e));//alu 
  
  register_r #(104) EXMEM(.clk(clk), .reset(reset),
                          .d({regwrite_e, resultsrc_e, memwrite_e, aluresult_e, regb_fwd, pcplus4_e, rd_e}),
                          .q({regwrite_m, resultsrc_m, memwrite_m, aluresult_m, regb_m, pcplus4_m, rd_m})); //exmem
  
  dmem dm(.clk(clk), .wd(regb_m), .addr(aluresult_m), .rd(memresult_m), .we(memwrite_m)); //data memory inst
  
  register_r #(103) memwb(.clk(clk), .reset(reset),
                        .d({regwrite_m, resultsrc_m, memresult_m, aluresult_m, pcplus4_m, rd_m}),
                          .q({regwrite_w, resultsrc_w, memresult_w, aluresult_w, pcplus4_w, rd_w})); //memwb
  
  mux4 muxy4(.d0(aluresult_w), .d1(memresult_w), .d2(pcplus4_w), .d3(), .s(resultsrc_w), .y(wd3)); //final result mux
                    
  hazardUnit hazardUnit(.clk(clk), .reset(reset), .rn_d(rn_d), .rm_d(rm_d), .rn_e(rn_e), .rm_e(rm_e), .rd_e(rd_e), .rd_m(rd_m), .rd_w(rd_w), .pcSrc(PCSrc), .resultSrc_E(resultsrc_e), .regWrite_M(regwrite_m), .regWrite_W(regwrite_w), .forwardA(forwardA), .forwardB(forwardB), .stall(stall), .branchTaken(branchTaken)); //hazard unit inst (new to lab 11)
  
endmodule
