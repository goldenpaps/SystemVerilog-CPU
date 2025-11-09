// Testbench for testing the VMI CPU

module vmi_tb();

  // signals to connect to cpu ports
  logic clk;
    
  // for syncing the test vectors
  logic reset;

  // expected results
  logic [31:0] resultExpected;
  logic [31:0]  addrExpected;

  // test vectors -- 32-bit expected address
  //  and 32-bit expected result
  logic [63:0] testvectors[0:999];
  integer vectornum, errors;
  integer numTests;
  integer cycleCount;

  // instantiate the cpu
  cpu uut(.clk(clk), .reset(reset));
    
  // generate clock
  always begin
      clk = 1; #5; clk = 0; #5;
  end
    
  // at start of test, load vectors
  // and pulse reset
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
      
    $readmemh("cpuTestVectors.txt", testvectors);
    
    // figure out how many tests there are
    numTests = 0;
    while(testvectors[numTests][0] !== 1'bx)
      numTests++;

    // initialize counters
    vectornum = 0;
    errors = 0;
    cycleCount = 0;
    
    // give a reset pulse
    reset = 1; #22; reset = 0;
  end
        
  // apply test vectors on falling edge of clk
  always @(negedge clk) begin
    resultExpected <= testvectors[vectornum][31:0];
    addrExpected <= testvectors[vectornum][63:32];
  end
    
  // check results after rising edge of clk
  always @(posedge clk)
    if (~reset) begin       // skip during reset
      cycleCount++;
      
      #1;
      
      // check for memory write, that address matches
      //  expected, and that data matches expected
      if (uut.dm.we === 1'b1) begin
          if ( (uut.dm.addr !== addrExpected) 
              || (uut.dm.wd !== resultExpected) ) 
        	begin
              $display("Error: outputs m[%h]=%h (m[%h]=%h expected)", 
                   uut.dm.addr, uut.dm.wd, 
                   addrExpected, resultExpected);
				errors++;
            end
        
		vectornum++;
      end

      if (vectornum >= numTests) begin
        $display("%d of %d tests complete with %d errors", 
                 vectornum, numTests, errors);
        $finish;
      end
      
      else if (cycleCount >= 1000) begin
        $display("ERROR -- Maximum clock cycles exceeded.");
        $display("%d of %d tests complete with %d errors",
                 vectornum, numTests, errors);
        $finish;
      end
    end
endmodule
