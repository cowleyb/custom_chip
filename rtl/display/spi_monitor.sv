module spi_monitor #(
    parameter int WIDTH  = 240,
    parameter int HEIGHT = 240
) (
    input logic clk,
    input logic rst_n,
    input logic sclk,
    input logic cs,
    input logic copi,
    input logic dc,

    output logic [31:0] pixel_x,
    output logic [31:0] pixel_y,
    output logic [15:0] pixel_rgb565,
    output logic pixel_valid,
    output logic frame_start,
    output logic frame_end
);

  logic sclk_d;
  logic [4:0] bit_count;
  logic [14:0] shift_reg;
  logic [31:0] next_x;
  logic [31:0] next_y;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      sclk_d <= 1'b0;
      bit_count <= '0;
      shift_reg <= '0;
      pixel_x <= '0;
      pixel_y <= '0;
      pixel_rgb565 <= '0;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      next_x <= '0;
      next_y <= '0;
    end else begin
      sclk_d <= sclk;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;

      if (cs || !dc) begin
        bit_count <= '0;
      end

      if (!sclk_d && sclk && !cs && dc) begin
        shift_reg <= {shift_reg[13:0], copi};

        if (bit_count == 5'd15) begin
          pixel_rgb565 <= {shift_reg, copi};
          pixel_x <= next_x;
          pixel_y <= next_y;
          pixel_valid <= 1'b1;
          frame_start <= (next_x == 0 && next_y == 0);
          frame_end <= (next_x == WIDTH - 1 && next_y == HEIGHT - 1);

          if (next_x == WIDTH - 1) begin
            next_x <= '0;
            if (next_y == HEIGHT - 1) begin
              next_y <= '0;
            end else begin
              next_y <= next_y + 1'b1;
            end
          end else begin
            next_x <= next_x + 1'b1;
          end

          bit_count <= '0;
        end else begin
          bit_count <= bit_count + 1'b1;
        end
      end
    end
  end

endmodule
