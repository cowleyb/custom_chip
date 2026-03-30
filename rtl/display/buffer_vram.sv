module buffer_vram #(
    parameter int RAM_WIDTH  = 240,
    parameter int DATA_WIDTH = 8
) (
    input logic write_clk,
    input logic write_addr,
    input logic write_data,

    input  logic read_clk,
    input  logic read_addr,
    output logic read_data
);

  logic [DATA_WIDTH-1:0] ram[0:RAM_WIDTH-1];


  always_ff @(posedge write_clk) begin
    ram[write_addr] <= write_data;
  end

  always_ff @(posedge read_clk) begin
    read_data <= ram[read_addr];
  end
endmodule
