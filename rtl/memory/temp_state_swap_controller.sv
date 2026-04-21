//TODO this will probably get recplaces when I start coding the CPU.
// For now this simply assigns bank swap 

module temp_state_swap_controller (
    input  logic clk,
    input  logic rst_n,
    output logic swap_banks,
    input  logic read_done,
    input  logic write_done,
    output logic start_render,
    output logic start_write
);

  typedef enum logic [2:0] {
    IDLE,
    PULSE_SWAP,
    PULSE_RESTART,
    WAIT_FOR_CLEAR
  } state_t;

  state_t state;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      start_render <= 1'b0;
      start_write <= 1'b0;
      swap_banks <= 1'b0;
    end else begin
      start_render <= 1'b0;
      start_write  <= 1'b0;
      swap_banks   <= 1'b0;
      case (state)
        IDLE: begin
          if (read_done && write_done) begin
            swap_banks <= 1'b1;
            state <= PULSE_SWAP;
          end
        end

        PULSE_SWAP: begin
          swap_banks <= 1'b0;
          state <= PULSE_RESTART;
        end

        PULSE_RESTART: begin
          start_render <= 1'b1;
          start_write <= 1'b1;
          state <= WAIT_FOR_CLEAR;
        end

        WAIT_FOR_CLEAR: begin
          if (!read_done && !write_done) begin
            start_render <= 1'b0;
            start_write <= 1'b0;
            state <= IDLE;
          end
        end
        default: state <= IDLE;
      endcase
    end

  end

endmodule
