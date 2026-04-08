module scanout_controller (
    input logic read_clk,
    input logic rst_n,
    input logic read_valid,
    input logic [15:0] read_data,
    input logic spi_done,
    output logic spi_start,
    output logic read_next,
    output logic [15:0] data_out

);

  typedef enum logic [2:0] {
    IDLE,
    START_SPI,
    WAIT_FOR_SPI,
    PULSE_NEXT_PIXEL,
    WAIT_FOR_NEXT_PIXEL
  } state_t;

  state_t state;

  always_ff @(posedge read_clk) begin
    if (!rst_n) begin
      data_out <= 16'b0;
      read_next <= 1'b0;
      state <= IDLE;
      spi_start <= 1'b0;
    end else begin
      spi_start <= 1'b0;
      read_next <= 1'b0;
      case (state)
        IDLE: begin
          if (read_valid) begin
            data_out <= read_data;
            state <= START_SPI;
          end
        end

        START_SPI: begin
          spi_start <= 1'b1;
          state <= WAIT_FOR_SPI;
        end

        WAIT_FOR_SPI: begin
          if (spi_done) begin
            state <= PULSE_NEXT_PIXEL;
          end
        end

        PULSE_NEXT_PIXEL: begin
          read_next <= 1'b1;
          state <= WAIT_FOR_NEXT_PIXEL;
        end

        WAIT_FOR_NEXT_PIXEL: begin
          if (!read_valid) begin
            state <= IDLE;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule
