module testbench();

  logic clk;
  logic reset;

  // instantiate device to be tested
  superscalar_top dut(clk, reset);

  // initialize test
  initial
    begin
      $dumpfile ("tb.vcd");
      $dumpvars (0, testbench);
      reset <= 1; # 8; reset <= 0;
      #150;
      $finish;
  end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
  end

endmodule
