module top (
    input logic clk,
    input logic rst_n,
    output logic [31:0] x,
    output logic [31:0] y,
    output logic valid,
    output logic frameEnd,
    output logic frameStart


);
  // Instantiate pixel
  renderer pTest (
      .clk(clk),
      .rst_n(rst_n),
      .x(x),
      .y(y),
      .frameEnd(frameEnd),
      .frameStart(frameStart),
      .valid(valid)
  );


endmodule
