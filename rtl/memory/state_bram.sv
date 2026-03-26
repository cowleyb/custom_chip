module state_bram (
    input logic [15:0] addr,
    output logic [15:0] pixel,
    input logic clk
);

  logic [15:0] mem[80*80-1];

  //TODO This is probably not synthesizible.
  initial begin
    $readmemh("rtl/memory/image.mem", mem);
  end

  always_ff @(posedge clk) begin
    pixel <= mem[addr];
  end
endmodule
