`timescale 1ns / 1ps

module state_bram_tb;

  localparam int DEPTH = 80 * 80;

  logic [15:0] addr;
  logic [15:0] pixel;
  logic clk;
  logic [15:0] ref_mem[DEPTH];

  int address_queue[$];

  state_bram dut (
      .addr (addr),
      .pixel(pixel),
      .clk  (clk)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $readmemh("rtl/memory/image.mem", ref_mem);
  end

  task automatic check_response(input logic [15:0] expected_addr);
    logic [15:0] expected_pixel;
    expected_pixel = ref_mem[expected_addr];
    if (pixel !== expected_pixel) begin
      $error("mismatch at addr %0d: expected %h, got %h", expected_addr, expected_pixel, pixel);
    end
  endtask

  initial begin
    int i;
    $display("=== Starting state_bram Testbench ===");
    addr = '0;

    repeat (2) @(posedge clk);

    $display("running sequential read test...");
    for (i = 0; i < 10; i++) begin
      addr <= i;
      address_queue.push_back(i);

      @(posedge clk);

      // only start checking once the first result has clocked out
      // BRAM latency is 1 wait until the 2nd cycle of the loop
      if (i >= 1) begin
        check_response(address_queue.pop_front());
      end
    end

    // get the last result that was requested in the last loop iteration
    @(posedge clk);
    check_response(address_queue.pop_front());

    $display("running sequential random test...");
    for (i = 0; i < 2; i++) begin
      int next_addr = $urandom_range(0, DEPTH - 1);
      addr <= next_addr;
      address_queue.push_back(next_addr);

      @(posedge clk);

      if (i >= 1) begin
        check_response(address_queue.pop_front());
      end
    end

    @(posedge clk);
    check_response(address_queue.pop_front());

    $display("=== Testbench completed successfully ===");
    #30 $finish;
  end

  initial begin
    $dumpfile("state_bram_tb.vcd");
    $dumpvars(0, state_bram_tb);
  end



endmodule
