`timescale 1ns / 1ps


module test;
  logic in1, in2, out;

  // Instantate DUT

  and_gate dut (
      .in1(in1),
      .in2(in2),
      .out(out)
  );

  initial begin
    in1 = 0;
    in2 = 0;
    #5 in1 = 1;
    #5 in2 = 1;
    #5 in1 = 0;
    #5 $finish;
  end


  initial $monitor("At time %t, in1 = %b, in2 = %b, out = %b", $time, in1, in2, out);

endmodule


