module fixed_shader (
    input logic clk,
    input logic [15:0] data_in,
    output logic [4:0] r,
    output logic [5:0] g,
    output logic [4:0] b
);

  always_ff @(posedge clk) begin
    //TODO

    b <= data_in[4:0];
    g <= data_in[10:5];
    r <= data_in[15:11];

  end


endmodule
