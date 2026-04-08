// Double line buffer
// ONe side is filling with new data, whilst one side is draining. THen they
// are swapped so the other side drains and the other side fills.
// can simulatanous read and write 

module buffer #(
    parameter int LINE_WIDTH = 240  //240 pixels
) (
    input logic write_clk,
    input logic read_clk,
    input logic rst_n,
    input logic [15:0] write_data,
    input logic write_valid,
    input logic read_next,
    output logic gpu_ready,
    output logic read_valid,
    output logic [15:0] read_data

);
  localparam logic [7:0] LAST_ADDR = 8'(LINE_WIDTH - 1);

  logic current_write_buffer;  //0 for A, 1 for B
  logic current_read_buffer;  //0 for A, 1 for B

  logic [7:0] write_address;
  logic [7:0] read_address;

  // Synchronizers for signals crossing between write and read clock domains.
  logic [2:0] spi_sync_shift;  //write -> readd
  logic [1:0] read_bank_sync_shift;  //read -> write
  logic [1:0] read_active_sync_shift;  //read -> write

  logic is_reading;
  logic read_done_toggle;
  logic read_valid_reg;
  logic read_wait_for_ram;
  logic read_capture_pending;
  logic read_valid_pending;

  logic write_enabled_a;
  logic write_enabled_b;
  logic [15:0] read_data_a;
  logic [15:0] read_data_b;
  logic [15:0] read_data_reg;
  logic synced_read_buffer;
  logic synced_is_reading;

  assign write_enabled_a = gpu_ready && write_valid && (current_write_buffer == 1'b0);
  assign write_enabled_b = gpu_ready && write_valid && (current_write_buffer == 1'b1);

  assign read_data = read_data_reg;
  buffer_vram buffer_a (
      .write_clk(write_clk),
      .write_addr(write_address),
      .write_data(write_data),
      .write_enabled(write_enabled_a),
      .read_clk(read_clk),
      .read_addr(read_address),
      .read_data(read_data_a)
  );

  buffer_vram buffer_b (
      .write_clk(write_clk),
      .write_addr(write_address),
      .write_data(write_data),
      .write_enabled(write_enabled_b),
      .read_clk(read_clk),
      .read_addr(read_address),
      .read_data(read_data_b)
  );

  always_ff @(posedge write_clk) begin
    if (!rst_n) begin
      read_bank_sync_shift <= 2'b00;
      read_active_sync_shift <= 2'b00;
    end else begin
      read_bank_sync_shift <= {read_bank_sync_shift[0], current_read_buffer};
      read_active_sync_shift <= {read_active_sync_shift[0], is_reading};
    end
  end

  assign synced_read_buffer = read_bank_sync_shift[1];
  assign synced_is_reading = read_active_sync_shift[1];
  assign gpu_ready = !synced_is_reading || (current_write_buffer != synced_read_buffer);

  always_ff @(posedge write_clk) begin
    if (!rst_n) begin
      write_address <= '0;
      current_write_buffer <= 1'b0;
    end else if (gpu_ready && write_valid) begin
      if (write_address == LAST_ADDR) begin
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
  assign read_valid = read_valid_reg;

  always_ff @(posedge read_clk) begin
    if (!rst_n) begin
      read_address <= '0;
      read_done_toggle <= 1'b0;
      is_reading <= 1'b0;
      read_valid_reg <= 1'b0;
      read_wait_for_ram <= 1'b0;
      read_capture_pending <= 1'b0;
      read_valid_pending <= 1'b0;
      read_data_reg <= '0;
      current_read_buffer <= 1'b0;
    end else begin
      if (buffer_swapped) begin
        read_address <= '0;
        is_reading <= 1'b1;
        read_valid_reg <= 1'b0;
        read_wait_for_ram <= 1'b1;
        read_capture_pending <= 1'b0;
        read_valid_pending <= 1'b0;
        current_read_buffer <= ~spi_sync_shift[1];
      end else if (is_reading && read_next) begin
        if (read_address == LAST_ADDR) begin
          read_address <= '0;
          is_reading <= 1'b0;
          read_valid_reg <= 1'b0;
          read_wait_for_ram <= 1'b0;
          read_capture_pending <= 1'b0;
          read_valid_pending <= 1'b0;
          read_done_toggle <= ~read_done_toggle;
        end else begin
          read_address <= read_address + 1'b1;
          read_valid_reg <= 1'b0;
          read_wait_for_ram <= 1'b1;
          read_capture_pending <= 1'b0;
          read_valid_pending <= 1'b0;
        end
      end else if (is_reading && read_wait_for_ram) begin
        // Wait one cycle for buffer_vram's registered output to update.
        read_wait_for_ram <= 1'b0;
        read_capture_pending <= 1'b1;
      end else if (is_reading && read_capture_pending) begin
        // Capture the RAM output into a stable buffer-owned register.
        read_data_reg <= (current_read_buffer == 1'b0) ? read_data_a : read_data_b;
        read_capture_pending <= 1'b0;
        read_valid_pending <= 1'b1;
      end else if (is_reading && read_valid_pending) begin
        read_valid_pending <= 1'b0;
        read_valid_reg <= 1'b1;
      end
    end
  end

endmodule
