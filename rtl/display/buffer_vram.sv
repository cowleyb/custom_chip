module buffer_vram #(
    parameter int RAM_WIDTH  = 240,
    parameter int DATA_WIDTH = 16
) (
    input logic write_clk,
    input logic [7:0] write_addr,
    input logic [DATA_WIDTH-1:0] write_data,

    input logic read_clk,
    input logic [7:0] read_addr,
    output logic [DATA_WIDTH-1:0] read_data,

    input logic write_enabled
);

  logic [DATA_WIDTH-1:0] ram[0:RAM_WIDTH-1];


  always_ff @(posedge write_clk) begin
    if (write_enabled) begin
      ram[write_addr] <= write_data;
    end
  end

  always_ff @(posedge read_clk) begin
    read_data <= ram[read_addr];
  end
endmodule
