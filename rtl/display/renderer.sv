module renderer #(
    parameter int WIDTH  = 240,
    parameter int HEIGHT = 240
) (
    input logic clk,
    input logic rst_n,
    output logic [31:0] x,
    output logic [31:0] y,
    output logic valid,
    output logic frameEnd,
    output logic frameStart

);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      x <= '0;
      y <= '0;
    end else begin
      if (x != WIDTH - 1) begin
        x <= x + 1;
      end else begin
        x <= '0;
        y <= (y == HEIGHT - 1 ? '0 : y + 1);
      end
    end

  end

  assign valid = (x < WIDTH) && (y < HEIGHT);
  assign frameEnd = (x == WIDTH - 1) && (y == HEIGHT - 1);
  assign frameStart = (x == 0) && (y == 0);

endmodule

