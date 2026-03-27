
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
  // Rnder produce x and y, 1 cycle delay in mem_fetch, 1 cycle delay in
  // state_bram, 1 cycle delay in shader
  localparam int LATENCY = 3;
  render_types_pkg::pixel_coord_t pixel_coord_pipeline[0:LATENCY-1];
  logic [31:0] render_x;
  logic [31:0] render_y;
  logic render_frame_start;
  logic render_frame_end;
  logic render_valid;

  renderer pTest (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .x(render_x),
      .y(render_y),
      .frame_end(render_frame_end),
      .frame_start(render_frame_start),
      .done(done),
      .valid(render_valid),
      .downstream_ready(downstream_ready),
      .ready(ready)
  );

  logic [12:0] addr;
  mem_fetch mem_fetch (
      .clk(clk),
      .x(render_x),
      .y(render_y),
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

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      foreach (pixel_coord_pipeline[i]) pixel_coord_pipeline[i] <= '0;
    end else begin
      pixel_coord_pipeline[0].x <= render_x;
      pixel_coord_pipeline[0].y <= render_y;
      pixel_coord_pipeline[0].frame_end <= render_frame_end;
      pixel_coord_pipeline[0].frame_start <= render_frame_start;
      pixel_coord_pipeline[0].valid <= render_valid;

      for (int i = 1; i < LATENCY; i++) begin
        pixel_coord_pipeline[i] <= pixel_coord_pipeline[i-1];
      end
    end
  end

  assign x = pixel_coord_pipeline[LATENCY-1].x;
  assign y = pixel_coord_pipeline[LATENCY-1].y;
  assign valid = pixel_coord_pipeline[LATENCY-1].valid;
  assign frame_end = pixel_coord_pipeline[LATENCY-1].frame_end;
  assign frame_start = pixel_coord_pipeline[LATENCY-1].frame_start;


endmodule
