
module mem_fetch (
    input logic [31:0] x,
    input logic [31:0] y,
    output logic [12:0] addr,
    input logic clk
);

  localparam int SCALING = 3;

  always_ff @(posedge clk) begin
    addr <= 13'((y / SCALING) * 80 + (x / SCALING));
  end
endmodule
