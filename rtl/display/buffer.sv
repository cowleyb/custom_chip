// Double line buffer
// ONe side is filling with new data, whilst one side is draining. THen they
// are swapped so the other side drains and the other side fills.
// can simulatanous read and write 

module buffer #(
    parameter int LINE_WIDTH = 240  //240 pixels
) (
    input  logic write_clk,
    input  logic read_clk,
    input  logic rst_n,
    input  logic write_data,
    input  logic write_valid,
    input  logic x,
    output logic hsync,
    output logic gpu_ready,
    output logic read_data

);
  logic current_write_buffer;  //0 for A, 1 for B
  logic current_read_buffer;  //0 for A, 1 for B

  logic [13:0] write_address;
  logic [13:0] read_address;
  logic write_enabled;

  // A 3bit shift register. 
  // bit [0] = the raw incoming bit (unsafe)
  // bit [1] = the synchronized bit (safe)
  // bit [2] = the delayed bit from last clock cycle (for edge detection)
  logic [2:0] spi_sync_shift;  //write -> readd
  logic [2:0] gpu_sync_shift;  //read -> write

  logic is_reading;
  logic read_done_toggle;

  logic write_enabled_a;
  logic write_enabled_b;
  logic read_data_a;
  logic read_data_b;

  assign we_a = gpu_ready && write_valid && (current_write_buffer == 1'b0);
  assign we_b = gpu_ready && write_valid && (current_write_buffer == 1'b1);

  assign read_data = (current_read_buffer == 1'b0) ? read_data_a : read_data_b;
  buffer_vram buffer_a (
      .write_clk(write_clk),
      .write_addr(write_address),
      .write_data(write_data),
      .write_enabled(write_enabled_a),
      .read_clk(read_clk),
      .read_addr(read_address),
      read_data(read_data_a)
  );

  buffer_vram buffer_b (
      .write_clk(write_clk),
      .write_addr(write_addr),
      .write_data(write_data),
      .write_enabled(write_enabled_b),
      .read_clk(read_clk),
      .read_addr(read_address),
      read_data(read_data_b)
  );

  always_ff @(posedge write_clk) begin
    if (!rst_n) begin
      gpu_sync_shift <= 3'b000;
    end else begin
      gpu_sync_shift <= {gpu_sync_shift[1:0], read_done_toggle};
    end
  end

  assign gpu_ready = current_write_buffer == gpu_sync_shift[1];

  always_ff @(posedge write_clk) begin
    if (!rst_n) begin
      write_address <= '0;
      current_write_buffer <= 1'b0;
    end else if (gpu_ready && write_valid) begin
      if (write_address == LINE_WIDTH - 1) begin
        write_address <= '0;
        current_write_buffer <= ~current_write_buffer;
      end else begin
        write_address <= write_address + 1'b1;
      end
    end
  end

  always_ff @(posedge read_clk) begin
    if (!rst_n) begin
      spi_sync_shift <= 3'b000;
    end else begin
      spi_sync_shift <= {spi_sync_shift[1:0], current_write_buffer};
    end
  end

  logic buffer_swapped;
  assign buffer_swapped = (spi_sync_shift[2] != spi_sync_shift[1]);

  always_ff @(posedge read_clk) begin
    if (!rst_n) begin
      read_address <= '0;
      read_done_toggle <= 1'b0;
      is_reading <= 1'b0;
      current_read_buffer <= 1'b0;
    end else begin
      if (buffer_swapped) begin
        is_reading <= 1'b1;
        current_read_buffer <= ~spi_sync_shift[1];
      end
      if (is_reading) begin

        if (read_address == LINE_WIDTH - 1) begin
          read_address <= '0;
          is_reading <= 1'b0;
          read_done_toggle <= ~read_done_toggle;
        end else begin
          read_address <= read_address + 1'b1;
        end
      end
    end
  end

endmodule



