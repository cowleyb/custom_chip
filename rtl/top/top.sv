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
    output logic frame_start,
    output logic [15:0] data,
    output logic [7:0] r,
    output logic [7:0] g,
    output logic [7:0] b
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

  logic [12:0] addr;
  mem_fetch mem_fetch (
      .clk(clk),
      .x(x),
      .y(y),
      .addr(addr)
  );

  // logic [15:0] data;
  state_bram state_bram (
      .clk (clk),
      .data(data),
      .addr(addr)
  );

  fixed_shader fixed_shader (
      .clk(clk),
      .data_in(data),
      .r(r),
      .g(g),
      .b(b)
  );



endmodule
