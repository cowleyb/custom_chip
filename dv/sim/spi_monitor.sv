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
  logic [7:0] current_command;
  logic [1:0] param_byte_index;
  logic awaiting_params;
  logic ram_write_active;
  logic [31:0] column_start;
  logic [31:0] column_end;
  logic [31:0] row_start;
  logic [31:0] row_end;
  logic [31:0] write_x;
  logic [31:0] write_y;
  logic [7:0] sampled_byte;
  logic [15:0] sampled_word;

  assign sampled_byte = {shift_reg[6:0], copi};
  assign sampled_word = {shift_reg, copi};

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      sclk_d <= 1'b0;
      bit_count <= '0;
      shift_reg <= '0;
      current_command <= 8'h00;
      param_byte_index <= '0;
      awaiting_params <= 1'b0;
      ram_write_active <= 1'b0;
      column_start <= 32'h0000;
      column_end <= WIDTH - 1;
      row_start <= 32'h0000;
      row_end <= HEIGHT - 1;
      pixel_x <= '0;
      pixel_y <= '0;
      pixel_rgb565 <= '0;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      write_x <= '0;
      write_y <= '0;
    end else begin
      sclk_d <= sclk;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;

      if (cs) begin
        bit_count <= '0;
      end

      if (!sclk_d && sclk && !cs) begin
        shift_reg <= {shift_reg[13:0], copi};

        if (!dc) begin
          if (bit_count == 5'd7) begin
            current_command <= sampled_byte;
            bit_count <= '0;
            param_byte_index <= '0;
            awaiting_params <= 1'b0;
            ram_write_active <= 1'b0;

            case (sampled_byte)
              8'h2A, 8'h2B: begin
                awaiting_params <= 1'b1;
              end
              8'h2C: begin
                write_x <= column_start;
                write_y <= row_start;
                ram_write_active <= 1'b1;
              end
              default: begin
              end
            endcase
          end else begin
            bit_count <= bit_count + 1'b1;
          end
        end else if (awaiting_params) begin
          if (bit_count == 5'd7) begin
            case (current_command)
              8'h2A: begin
                case (param_byte_index)
                  2'd0: column_start[15:8] <= sampled_byte;
                  2'd1: column_start[7:0] <= sampled_byte;
                  2'd2: column_end[15:8] <= sampled_byte;
                  2'd3: column_end[7:0] <= sampled_byte;
                endcase
              end
              8'h2B: begin
                case (param_byte_index)
                  2'd0: row_start[15:8] <= sampled_byte;
                  2'd1: row_start[7:0] <= sampled_byte;
                  2'd2: row_end[15:8] <= sampled_byte;
                  2'd3: row_end[7:0] <= sampled_byte;
                endcase
              end
              default: begin
              end
            endcase

            if (param_byte_index == 2'd3) begin
              param_byte_index <= '0;
              awaiting_params <= 1'b0;
            end else begin
              param_byte_index <= param_byte_index + 1'b1;
            end

            bit_count <= '0;
          end else begin
            bit_count <= bit_count + 1'b1;
          end
        end else if (ram_write_active) begin
          if (bit_count == 5'd15) begin
            pixel_rgb565 <= sampled_word;
            pixel_x <= write_x;
            pixel_y <= write_y;
            pixel_valid <= 1'b1;
            frame_start <= (write_x == column_start && write_y == row_start);
            frame_end <= (write_x == column_end && write_y == row_end);

            if (write_x == column_end) begin
              write_x <= column_start;
              if (write_y == row_end) begin
                write_y <= row_start;
              end else begin
                write_y <= write_y + 1'b1;
              end
            end else begin
              write_x <= write_x + 1'b1;
            end

            bit_count <= '0;
          end else begin
            bit_count <= bit_count + 1'b1;
          end
        end else begin
          bit_count <= '0;
        end
      end
    end
  end

endmodule
