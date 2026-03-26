module top (
    input logic clk,
    input logic rst_n,
    input logic start,
    output logic [31:0] x,
    output logic [31:0] y,
    output logic valid,
    output logic frame_end,
    output logic done,
    input logic downstream_ready,
    output logic ready,
    output logic frame_start
);
  // Instantiate pixel
  renderer pTest (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .x(x),
      .y(y),
      .frame_end(frame_end),
      .frame_start(frame_start),
      .done(done),
      .valid(valid),
      .downstream_ready(downstream_ready),
      .ready(ready)
  );


endmodule
