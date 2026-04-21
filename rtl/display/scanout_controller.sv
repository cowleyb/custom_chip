module scanout_controller #(
    parameter int WIDTH  = 240,
    parameter int HEIGHT = 240
) (
    input logic read_clk,
    input logic rst_n,
    input logic read_valid,
    input logic [15:0] read_data,
    input logic spi_done,
    output logic spi_start,
    output logic spi_dc,
    output logic spi_is_command,
    output logic frame_done,
    output logic read_next,
    output logic [15:0] data_out

);

  typedef enum logic [2:0] {
    IDLE,
    LOAD_SETUP,
    START_SPI,
    WAIT_FOR_SPI,
    PULSE_NEXT_PIXEL,
    WAIT_FOR_NEXT_PIXEL
  } state_t;

  state_t state;
  logic frame_in_progress;
  logic setup_phase;
  logic [3:0] setup_index;
  logic [31:0] pixel_count;

  localparam logic [3:0] LAST_SETUP_INDEX = 4'd10;
  localparam logic [15:0] COL_END = 16'(WIDTH - 1);
  localparam logic [15:0] ROW_END = 16'(HEIGHT - 1);
  localparam logic [31:0] TOTAL_PIXELS = WIDTH * HEIGHT;

  function automatic logic [15:0] setup_word(input logic [3:0] index);
    case (index)
      4'd0: setup_word = 16'h002A;
      4'd1: setup_word = 16'h0000;
      4'd2: setup_word = 16'h0000;
      4'd3: setup_word = 16'h0000;
      4'd4: setup_word = {8'h00, COL_END[7:0]};
      4'd5: setup_word = 16'h002B;
      4'd6: setup_word = 16'h0000;
      4'd7: setup_word = 16'h0000;
      4'd8: setup_word = 16'h0000;
      4'd9: setup_word = {8'h00, ROW_END[7:0]};
      4'd10: setup_word = 16'h002C;
      default: setup_word = 16'h0000;
    endcase
  endfunction

  function automatic logic setup_dc(input logic [3:0] index);
    case (index)
      4'd0, 4'd5, 4'd10: setup_dc = 1'b0;
      default: setup_dc = 1'b1;
    endcase
  endfunction

  always_ff @(posedge read_clk) begin
    if (!rst_n) begin
      data_out <= 16'b0;
      spi_dc <= 1'b0;
      spi_is_command <= 1'b1;
      frame_done <= 1'b0;
      read_next <= 1'b0;
      state <= IDLE;
      spi_start <= 1'b0;
      frame_in_progress <= 1'b0;
      setup_phase <= 1'b0;
      setup_index <= '0;
      pixel_count <= '0;
    end else begin
      spi_start <= 1'b0;
      frame_done <= 1'b0;
      read_next <= 1'b0;
      case (state)
        IDLE: begin
          if (!frame_in_progress) begin
            if (read_valid) begin
              frame_in_progress <= 1'b1;
              setup_phase <= 1'b1;
              setup_index <= '0;
              state <= LOAD_SETUP;
            end
          end else if (setup_phase) begin
            state <= LOAD_SETUP;
          end else if (read_valid) begin
            data_out <= read_data;
            spi_dc <= 1'b1;
            spi_is_command <= 1'b0;
            state <= START_SPI;
          end
        end

        LOAD_SETUP: begin
          data_out <= setup_word(setup_index);
          spi_dc <= setup_dc(setup_index);
          spi_is_command <= 1'b1;
          state <= START_SPI;
        end

        START_SPI: begin
          spi_start <= 1'b1;
          state <= WAIT_FOR_SPI;
        end

        WAIT_FOR_SPI: begin
          if (spi_done) begin
            if (setup_phase) begin
              if (setup_index == LAST_SETUP_INDEX) begin
                setup_phase <= 1'b0;
                state <= IDLE;
              end else begin
                setup_index <= setup_index + 1'b1;
                state <= LOAD_SETUP;
              end
            end else begin
              state <= PULSE_NEXT_PIXEL;
            end
          end
        end

        PULSE_NEXT_PIXEL: begin
          read_next <= 1'b1;
          if (pixel_count == TOTAL_PIXELS - 1) begin
            pixel_count <= '0;
            frame_in_progress <= 1'b0;
            frame_done <= 1'b1;
          end else begin
            pixel_count <= pixel_count + 1'b1;
          end
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
