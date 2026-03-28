
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
    output logic [4:0] r,
    output logic [5:0] g,
    output logic [4:0] b
);
  // Renderer produces coordinates, then mem_fetch, BRAM, and shader each add
  // one cycle of latency before a final pixel is ready.
  localparam int LATENCY = 3;
  render_types_pkg::pixel_meta_t metadata_pipeline[0:LATENCY-1];
  render_types_pkg::pixel_meta_t render_meta;
  render_types_pkg::pixel_stream_t pixel_stream;
  logic [31:0] render_x;
  logic [31:0] render_y;
  logic render_frame_start;
  logic render_frame_end;
  logic render_valid;

  assign render_meta.x = render_x;
  assign render_meta.y = render_y;
  assign render_meta.valid = render_valid;
  assign render_meta.frame_start = render_frame_start;
  assign render_meta.frame_end = render_frame_end;

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
      .r(pixel_stream.r),
      .g(pixel_stream.g),
      .b(pixel_stream.b)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      foreach (metadata_pipeline[i]) metadata_pipeline[i] <= '0;
    end else begin
      metadata_pipeline[0] <= render_meta;

      for (int i = 1; i < LATENCY; i++) begin
        metadata_pipeline[i] <= metadata_pipeline[i-1];
      end
    end
  end

  assign pixel_stream.x = metadata_pipeline[LATENCY-1].x;
  assign pixel_stream.y = metadata_pipeline[LATENCY-1].y;
  assign pixel_stream.frame_start = metadata_pipeline[LATENCY-1].frame_start;
  assign pixel_stream.frame_end = metadata_pipeline[LATENCY-1].frame_end;

  assign x = pixel_stream.x;
  assign y = pixel_stream.y;
  assign valid = metadata_pipeline[LATENCY-1].valid;
  assign frame_end = pixel_stream.frame_end;
  assign frame_start = pixel_stream.frame_start;
  assign r = pixel_stream.r;
  assign g = pixel_stream.g;
  assign b = pixel_stream.b;


endmodule
