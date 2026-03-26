`timescale 1ns / 1ps

module state_bram_tb;

  logic [15:0] addr;
  logic [15:0] pixel;
  logic clk;

  state_bram dut (
      .addr (addr),
      .pixel(pixel),
      .clk  (clk)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  int i;
  initial begin
    // Report start
    $display("=== Starting state_bram Testbench ===");

    // Wait for initial memory load
    @(posedge clk);

    // Sequential read test
    $display("running sequential read test...");
    for (i = 0; i < 2; i++) begin
      @(negedge clk);
      addr <= i;
      @(posedge clk);
      #1
      if (pixel !== dut.mem[i]) begin
        $error("mismatch at addr %0d: expected %h, got %h", i, dut.mem[i], pixel);
      end
    end
    // // Random access test
    // $display("Running random access test...");
    // for (i = 0; i < 10; i++) begin
    //   addr <= $urandom_range(0, 80 * 80 - 1);
    //   @(posedge clk);
    //   if (pixel !== dut.mem[addr]) begin
    //     $error("Random access mismatch at addr %0d: expected %h, got %h", addr, dut.mem[addr],
    //            pixel);
    //   end
    // end
    //
    $display("=== Testbench completed successfully ===");
    #30 $finish;
  end

  initial begin
    $dumpfile("state_bram_tb.vcd");
    $dumpvars(0, state_bram_tb);
  end



endmodule
