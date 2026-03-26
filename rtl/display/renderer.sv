module renderer #(
    parameter int WIDTH  = 240,
    parameter int HEIGHT = 240
) (
    input logic clk,
    input logic rst_n,

    input  logic start,
    output logic ready,

    output logic [31:0] x,
    output logic [31:0] y,
    output logic        valid,
    input  logic        downstream_ready,

    output logic frame_end,
    output logic frame_start,
    output logic done
);

  typedef enum logic {
    IDLE,
    ACTIVE
  } state_t;
  state_t state;

  logic   pipe_en;
  assign pipe_en = valid && downstream_ready;

  // ready is high when we are not busy
  assign ready   = (state == IDLE);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state       <= IDLE;
      x           <= '0;
      y           <= '0;
      valid       <= 1'b0;
      frame_start <= 1'b0;
      frame_end   <= 1'b1;  // Default to end-state or 0
      done        <= 1'b0;
    end else begin
      // Pulse clearing
      frame_start <= 1'b0;
      frame_end   <= 1'b0;
      done        <= 1'b0;

      case (state)
        IDLE: begin
          if (start) begin
            state       <= ACTIVE;
            valid       <= 1'b1;
            x           <= '0;
            y           <= '0;
            // Frame start logic
            frame_start <= 1'b1;
          end
        end

        ACTIVE: begin
          if (pipe_en) begin
            if (x == WIDTH - 1 && y == HEIGHT - 1) begin
              state     <= IDLE;
              valid     <= 1'b0;
              frame_end <= 1'b1;
              done      <= 1'b1;
            end else if (x == WIDTH - 1) begin
              x <= '0;
              y <= y + 1'b1;
            end else begin
              x <= x + 1'b1;
            end
          end
        end
      endcase
    end
  end
endmodule



