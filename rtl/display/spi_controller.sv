module spi_controller (
    input logic clk,
    input logic rst_n,
    input logic [15:0] data_in,
    input logic start,
    input logic dc_in,  //command or data. low (0) = command, high (1) = data
    input logic is_command,  //commands usually 8 bit.
    output logic sclk,
    output logic cs,
    output logic copi,
    output logic busy,
    output logic done,
    output logic dc
);

  typedef enum logic [1:0] {
    IDLE,
    CLK_HIGH,
    CLK_LOW,
    COMPLETE
  } spi_state_t;

  spi_state_t state;
  logic [14:0] shift_reg;
  logic [4:0] bit_count;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      shift_reg <= '0;
      bit_count <= '0;
      sclk <= 1'b0;
      cs <= 1'b1;
      copi <= 1'b0;
      busy <= 1'b0;
      done <= 1'b0;
      dc <= 1'b0;
    end else begin
      done <= 1'b0;

      case (state)
        IDLE: begin
          sclk <= 1'b0;
          cs   <= 1'b1;
          busy <= 1'b0;
          copi <= 1'b0;

          if (start) begin
            if (is_command) begin
              bit_count <= 5'd7;
              shift_reg <= {8'b0, data_in[6:0]};
              copi <= data_in[7];
            end else begin
              bit_count <= 5'd15;
              shift_reg <= data_in[14:0];
              copi <= data_in[15];
            end
            cs <= 1'b0;
            busy <= 1'b1;
            state <= CLK_HIGH;
            dc <= dc_in;
          end
        end

        CLK_HIGH: begin
          // in SPI mode 0, the receiver samples on the rising clock edge.
          sclk  <= 1'b1;
          busy  <= 1'b1;
          state <= CLK_LOW;
        end

        CLK_LOW: begin
          sclk <= 1'b0;
          busy <= 1'b1;

          if (bit_count == 0) begin
            state <= COMPLETE;
          end else begin
            shift_reg <= {shift_reg[13:0], 1'b0};
            bit_count <= bit_count - 1'b1;
            copi <= shift_reg[14];
            state <= CLK_HIGH;
          end
        end

        COMPLETE: begin
          sclk <= 1'b0;
          cs <= 1'b1;
          busy <= 1'b0;
          copi <= 1'b0;
          done <= 1'b1;
          state <= IDLE;
        end

        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
