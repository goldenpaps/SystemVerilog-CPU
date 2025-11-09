//new hazard unit module for lab11
module hazardUnit(input logic clk,
                  input logic reset,
                  input logic [3:0] rn_d,
                  input logic [3:0] rm_d,
                  input logic [3:0] rn_e,
                  input logic [3:0] rm_e,
                  input logic [3:0] rd_e,
                  input logic [3:0] rd_m,
                  input logic [3:0] rd_w,
                  input logic [1:0] pcSrc,
                  input logic [1:0] resultSrc_E,
                  input logic regWrite_M,
                  input logic regWrite_W,
                  output logic [1:0] forwardA,
                  output logic [1:0] forwardB,
                  output logic stall,
                  output logic branchTaken);
  //forward assignment a
  assign forwardA = ((rd_m == rn_e) & regWrite_M) ? 2'b10
    : ((rd_w == rn_e) & regWrite_W) ? 2'b01
			: 2'b00;
  //forward assignment b
  assign forwardB = ((rd_m == rm_e) & regWrite_M) ? 2'b10
    : ((rd_w == rm_e) & regWrite_W) ? 2'b01
			: 2'b00;
  //stall assignment
  assign stall = ((rn_d == rd_e) | (rm_d == rd_e)) & (resultSrc_E == 2'b01); 
  //if pcsrc is selecting an option other then pcplus4, then branchtaken is a 1
  assign branchTaken = (pcSrc != 2'b00);
  
endmodule
