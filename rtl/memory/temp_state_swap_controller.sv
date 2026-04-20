//TODO this will probably get recplaces when I start coding the CPU.
// For now this simply assigns bank swap 

module temp_state_swap_controller (
    input  logic clk,
    input  logic rst_n,
    output logic swap_banks,
    input  logic read_done,
    input  logic write_done
);

  typedef enum logic {
    IDLE,
    PULSE_SWAP
  } state_t;

  state_t state;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      swap_banks <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (read_done && write_done) begin
            swap_banks <= 1'b1;
            state <= PULSE_SWAP;
          end
        end

        PULSE_SWAP: begin
          swap_banks <= 1'b0;
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end

  end

endmodule
