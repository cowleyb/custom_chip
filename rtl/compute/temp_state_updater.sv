// This is a simple state updater before NPU/TPU does
// the real compututing


module temp_state_updater (
    input logic clk,
    input logic rst_n,
    input logic start_write,
    output logic write_done,
    output logic [12:0] write_addr,
    output logic [15:0] write_data,
    output logic write_enable
);
  localparam [12:0] TOTAL_COUNT = 80 * 80;

  typedef enum logic [1:0] {
    IDLE,
    WRITING
  } state_t;
  state_t state;

  logic [15:0] init_mem[0:6399];
  initial $readmemh("rtl/memory/image.mem", init_mem);

  always_comb begin
    write_data = init_mem[write_addr];
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state        <= IDLE;
      write_addr   <= '0;
      write_done   <= 1'b0;
      write_enable <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (start_write) begin
            state <= WRITING;
            write_addr <= '0;
            write_done <= 1'b0;
            write_enable <= 1'b1;
          end
        end

        WRITING: begin
          if (write_addr == TOTAL_COUNT - 1) begin
            write_done <= 1'b1;
            state <= IDLE;
            write_enable <= 1'b0;
          end else begin
            write_addr <= write_addr + 1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
