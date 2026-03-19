`timescale 1ns / 1ps


module test_tb;
  logic in1, in2, out;

  // instantate dut


  initial begin
  end


  initial $monitor("at time %t, in1 = %b, in2 = %b, out = %b", $time, in1, in2, out);

endmodule


