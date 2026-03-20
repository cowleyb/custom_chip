module top (
    input logic clk,
    input logic reset,
    output logic [31:0] out
);
  // Instantiate pixel
  pixel pTest (
      .clk  (clk),
      .out  (out),
      .reset(reset)
  );


endmodule
