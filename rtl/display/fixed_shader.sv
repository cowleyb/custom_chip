module fixed_shader (

    input logic clk,
    input logic [15:0] data_in,
    output [7:0] r,
    output [7:0] g,
    output [7:0] b
);

  always_ff @(posedge clk) begin
    //TODO

    // r <= ({3'b000, data_in[4:0] << 3}) | ({3'b000, data_in[4:0] >> 2});
    // g <= ({2'b00, data_in[10:5] << 2}) | ({2'b00, data_in[10:5] >> 1});
    // b <= ({3'b000, data_in[15:11] << 3}) | ({3'b000, data_in[15:11] >> 2});
    // r <= 8'b00000000;
    // g <= 8'b11111111;
    // b <= 8'b11111111;
    b <= data_in[4:0] << 3;
    g <= data_in[10:5] << 2;
    r <= data_in[15:11] << 3;

  end


endmodule
