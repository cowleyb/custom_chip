module top (
    input logic clk,
    input logic rst_n,
    input logic start,
    output logic [31:0] x,
    output logic [31:0] y,
    output logic valid,
    output logic frame_end,
    output logic done,
    output logic ready,
    output logic frame_start,
    output logic [15:0] buffer_data,
    output logic [4:0] r,
    output logic [5:0] g,
    output logic [4:0] b,
    output logic hsync,
    output logic spi_sclk,
    output logic spi_cs,
    output logic spi_copi,
    output logic spi_dc,
    output logic spi_busy
`ifdef VERILATOR_SIM
    ,
    output logic [31:0] monitor_x,
    output logic [31:0] monitor_y,
    output logic [15:0] monitor_rgb565,
    output logic monitor_pixel_valid,
    output logic monitor_frame_start,
    output logic monitor_frame_end
`endif
);
  // Renderer produces coordinates, then mem_fetch, BRAM, and shader each add
  // one cycle of latency before a final pixel is ready.
  localparam int LATENCY = 3;

  logic [31:0] metadata_x_pipeline[0:LATENCY-1];
  logic [31:0] metadata_y_pipeline[0:LATENCY-1];
  logic metadata_valid_pipeline[0:LATENCY-1];
  logic metadata_frame_start_pipeline[0:LATENCY-1];
  logic metadata_frame_end_pipeline[0:LATENCY-1];
  render_types_pkg::pixel_stream_t pixel_stream;

  logic [31:0] render_x;
  logic [31:0] render_y;
  logic render_frame_start;
  logic render_frame_end;
  logic render_valid;
  logic renderer_ready;
  logic renderer_done;

  logic [4:0] pixel_r;
  logic [5:0] pixel_g;
  logic [4:0] pixel_b;
  logic pixel_valid;
  logic [15:0] shader_rgb565;

  logic buffer_gpu_ready;
  logic buffer_read_valid;
  logic buffer_read_next;
  logic [15:0] buffer_read_data;

  logic scanout_spi_start;
  logic scanout_spi_dc;
  logic scanout_spi_is_command;
  logic [15:0] scanout_data;
  logic spi_done;

  logic swap_banks;
  // logic read_done;
  logic write_done;
  logic [12:0] write_addr;
  logic [15:0] write_data;
  logic write_enable;
  logic start_render;
  logic restart_render;
  logic restart_write;
  logic start_write;
  logic [12:0] addr;

  // For simplicity, tie the first render and write start signals to the
  // external start.
 assign start_write = start | restart_write;
 assign start_render = start | restart_render;
  
  temp_state_updater temp_state_updater (
    .clk(clk),
    .rst_n(rst_n),
    .start_write(start_write),
    .write_done(write_done),
    .write_addr(write_addr),
    .write_data(write_data),
    .write_enable(write_enable)
  );

  temp_state_swap_controller temp_state_swap_controller (
    .clk(clk),
    .rst_n(rst_n),
    .swap_banks(swap_banks), 
    .read_done(renderer_done),
    .write_done(write_done), // TODO need to track when the line buffer is done writing a frame
    .start_render(restart_render),
    .start_write(restart_write)
    );

  state_store state_store (
    .clk(clk),
    .rst_n(rst_n),
    .read_addr(addr),
    .read_data(buffer_data),
    .write_addr(write_addr), // TODO 
    .write_data(write_data), // TODO 
    .write_enabled(write_enable), // TODO
    .swap_banks(swap_banks)  // TODO 
    );

  renderer pTest (
      .clk(clk),
      .rst_n(rst_n),
      .start(start_render),
      .x(render_x),
      .y(render_y),
      .frame_end(render_frame_end),
      .frame_start(render_frame_start),
      .done(renderer_done),
      .valid(render_valid),
      .downstream_ready(buffer_gpu_ready),
      .ready(renderer_ready)
  );

  mem_fetch mem_fetch (
      .clk(clk),
      .x(render_x),
      .y(render_y),
      .addr(addr)
      );

  fixed_shader fixed_shader (
      .clk(clk),
      .data_in(buffer_data),
      .r(pixel_r),
      .g(pixel_g),
      .b(pixel_b)
  );

  // Align metadata with the shader output so the line buffer writes complete pixels.
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      foreach (metadata_x_pipeline[i]) begin
        metadata_x_pipeline[i] <= '0;
        metadata_y_pipeline[i] <= '0;
        metadata_valid_pipeline[i] <= 1'b0;
        metadata_frame_start_pipeline[i] <= 1'b0;
        metadata_frame_end_pipeline[i] <= 1'b0;
      end
    end else begin
      metadata_x_pipeline[0] <= render_x;
      metadata_y_pipeline[0] <= render_y;
      metadata_valid_pipeline[0] <= render_valid;
      metadata_frame_start_pipeline[0] <= render_frame_start;
      metadata_frame_end_pipeline[0] <= render_frame_end;

      for (int i = 1; i < LATENCY; i++) begin
        metadata_x_pipeline[i] <= metadata_x_pipeline[i-1];
        metadata_y_pipeline[i] <= metadata_y_pipeline[i-1];
        metadata_valid_pipeline[i] <= metadata_valid_pipeline[i-1];
        metadata_frame_start_pipeline[i] <= metadata_frame_start_pipeline[i-1];
        metadata_frame_end_pipeline[i] <= metadata_frame_end_pipeline[i-1];
      end
    end
  end

  assign pixel_valid = metadata_valid_pipeline[LATENCY-1];
  assign shader_rgb565 = {pixel_r, pixel_g, pixel_b};

  assign pixel_stream.x = metadata_x_pipeline[LATENCY-1];
  assign pixel_stream.y = metadata_y_pipeline[LATENCY-1];
  assign pixel_stream.frame_start = metadata_frame_start_pipeline[LATENCY-1];
  assign pixel_stream.frame_end = metadata_frame_end_pipeline[LATENCY-1];
  assign pixel_stream.r = pixel_r;
  assign pixel_stream.g = pixel_g;
  assign pixel_stream.b = pixel_b;

  assign x = pixel_stream.x;
  assign y = pixel_stream.y;
  assign valid = pixel_valid;
  assign frame_start = pixel_stream.frame_start;
  assign frame_end = pixel_stream.frame_end;
  assign done = renderer_done;
  assign ready = renderer_ready;
  assign r = pixel_stream.r;
  assign g = pixel_stream.g;
  assign b = pixel_stream.b;

  buffer buffer (
      .write_clk(clk),
      .read_clk(clk),
      .rst_n(rst_n),
      .write_data(shader_rgb565),
      .write_valid(pixel_valid),
      .read_next(buffer_read_next),
      .gpu_ready(buffer_gpu_ready),
      .read_valid(buffer_read_valid),
      .read_data(buffer_read_data)
  );

  assign hsync = 1'b0;

  scanout_controller scanout_controller (
      .read_clk(clk),
      .rst_n(rst_n),
      .read_valid(buffer_read_valid),
      .read_data(buffer_read_data),
      .spi_done(spi_done),
      .spi_start(scanout_spi_start),
      .spi_dc(scanout_spi_dc),
      .spi_is_command(scanout_spi_is_command),
      .read_next(buffer_read_next),
      .data_out(scanout_data)
  );

  spi_controller spi_controller (
      .clk(clk),
      .rst_n(rst_n),
      .start(scanout_spi_start),
      .is_command(scanout_spi_is_command),
      .data_in(scanout_data),
      .dc_in(scanout_spi_dc),
      .sclk(spi_sclk),
      .cs(spi_cs),
      .copi(spi_copi),
      .busy(spi_busy),
      .done(spi_done),
      .dc(spi_dc)
  );

`ifdef VERILATOR_SIM
  spi_monitor spi_monitor (
      .clk(clk),
      .rst_n(rst_n),
      .sclk(spi_sclk),
      .cs(spi_cs),
      .copi(spi_copi),
      .dc(spi_dc),
      .pixel_x(monitor_x),
      .pixel_y(monitor_y),
      .pixel_rgb565(monitor_rgb565),
      .pixel_valid(monitor_pixel_valid),
      .frame_start(monitor_frame_start),
      .frame_end(monitor_frame_end)
  );
`endif
endmodule
