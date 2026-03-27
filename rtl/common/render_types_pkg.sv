package render_types_pkg;

  typedef struct packed {
    logic [31:0] x;
    logic [31:0] y;
    logic valid;
    logic frame_start;
    logic frame_end;
  } pixel_coord_t;

  typedef struct packed {
    logic [7:0] r;
    logic [7:0] g;
    logic [7:0] b;

  } pixel_data_t;

endpackage
