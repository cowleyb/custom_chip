module pixel (
    input logic clk,
    input logic reset,
    output logic [31:0] out
);
  always_ff @(posedge clk or posedge reset) begin
    if (reset) out <= 32'b0;
    else out <= out + 1;
  end
endmodule
