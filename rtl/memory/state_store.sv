
module state_store #(
    parameter int DATA_WIDTH = 16,
    parameter int ADDRESS_WIDTH = 13
) (
    input logic clk,
    input logic rst_n,

    input logic [ADDRESS_WIDTH-1:0] read_addr,
    output logic [DATA_WIDTH-1:0] read_data,

    input logic [ADDRESS_WIDTH-1:0] write_addr,
    input logic [DATA_WIDTH-1:0] write_data,
    input logic write_enabled,

    input logic swap_banks  // pulse to swap banks after a frame is done controlled by a future CPU???
);

  logic front_bank;  //0 for A, 1 for B
  logic [DATA_WIDTH-1:0] read_data_a;
  logic [DATA_WIDTH-1:0] read_data_b;
  assign read_data = (front_bank == 1'b0) ? read_data_a : read_data_b;

  state_bram bank_a (
      .write_addr(write_addr),
      .write_data(write_data),
      .write_enabled(write_enabled && (front_bank == 1'b1)),
      .read_data(read_data_a),
      .read_addr(read_addr),
      .clk(clk)
  );

  state_bram bank_b (
      .write_addr(write_addr),
      .write_data(write_data),
      .write_enabled(write_enabled && (front_bank == 1'b0)),
      .read_data(read_data_b),
      .read_addr(read_addr),
      .clk(clk)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      front_bank <= 1'b0;
    end else if (swap_banks) begin
      front_bank <= ~front_bank;
    end
  end

endmodule
