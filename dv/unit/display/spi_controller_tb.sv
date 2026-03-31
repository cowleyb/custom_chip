`timescale 1ns / 1ps

module spi_controller_tb;

  logic clk;
  logic rst_n;
  logic [15:0] rgb;
  logic start;
  logic sclk;
  logic cs;
  logic copi;
  logic busy;
  logic done;

  int sampled_bits;
  logic [15:0] observed_word;

  spi_controller dut (
      .clk  (clk),
      .rst_n(rst_n),
      .rgb  (rgb),
      .start(start),
      .sclk (sclk),
      .cs   (cs),
      .copi (copi),
      .busy (busy),
      .done (done)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic start_transfer(input logic [15:0] word);
    begin
      @(negedge clk);
      sampled_bits = 0;
      observed_word = '0;
      rgb = word;
      start = 1'b1;
      @(negedge clk);
      start = 1'b0;
    end
  endtask

  task automatic wait_for_done;
    begin
      while (done !== 1'b1) begin
        @(posedge clk);
      end
    end
  endtask

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      sampled_bits <= 0;
      observed_word <= '0;
    end
  end

  always @(posedge sclk) begin
    if (!cs) begin
      observed_word <= {observed_word[14:0], copi};
      sampled_bits <= sampled_bits + 1;
    end
  end

  initial begin
    $dumpfile("spi_controller_tb.vcd");
    $dumpvars(0, spi_controller_tb);
  end

  initial begin
    $display("=== Starting spi_controller Testbench ===");

    rst_n = 1'b0;
    rgb = '0;
    start = 1'b0;
    sampled_bits = 0;
    observed_word = '0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    if (cs !== 1'b1 || sclk !== 1'b0 || busy !== 1'b0) begin
      $error("idle state incorrect after reset: cs=%b sclk=%b busy=%b", cs, sclk, busy);
    end

    $display("running first transfer...");
    start_transfer(16'hA5C3);
    wait_for_done();
    @(posedge clk);

    if (sampled_bits !== 16) begin
      $error("expected 16 sampled bits, got %0d", sampled_bits);
    end

    if (observed_word !== 16'hA5C3) begin
      $error("expected MSB-first word A5C3, got %h", observed_word);
    end

    if (cs !== 1'b1 || sclk !== 1'b0 || busy !== 1'b0) begin
      $error("controller did not return to idle after first transfer");
    end

    $display("running second transfer...");
    start_transfer(16'h07E0);
    wait_for_done();
    @(posedge clk);

    if (sampled_bits !== 16) begin
      $error("expected 16 sampled bits on second transfer, got %0d", sampled_bits);
    end

    if (observed_word !== 16'h07E0) begin
      $error("expected MSB-first word 07E0, got %h", observed_word);
    end

    $display("=== Testbench completed successfully ===");
    #20 $finish;
  end

endmodule
