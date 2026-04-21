module state_bram #(
    parameter int DATA_WIDTH = 16,
    parameter int ADDRESS_WIDTH = 13
) (

    input logic [ADDRESS_WIDTH-1:0] write_addr,
    input logic [DATA_WIDTH-1:0] write_data,
    input logic write_enabled,

    output logic [DATA_WIDTH-1:0] read_data,
    input logic [ADDRESS_WIDTH-1:0] read_addr,

    input logic clk
);

  localparam int DEPTH = 80 * 80;
  logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];

  always_ff @(posedge clk) begin
    read_data <= mem[read_addr];
    if (write_enabled) begin
      mem[write_addr] <= write_data;
    end

  end
endmodule
