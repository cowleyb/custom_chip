package render_types_pkg;

  typedef struct packed {
    logic [31:0] x;
    logic [31:0] y;
  } pixel_coord_t;

  typedef struct packed {
    logic [31:0] x;
    logic [31:0] y;
    logic        valid;
    logic        frame_start;
    logic        frame_end;
  } pixel_meta_t;

  typedef struct packed {
    logic [4:0] r;
    logic [5:0] g;
    logic [4:0] b;

  } pixel_data_t;

  typedef struct packed {
    logic [31:0] x;
    logic [31:0] y;
    logic        frame_start;
    logic        frame_end;
    logic [4:0]  r;
    logic [5:0]  g;
    logic [4:0]  b;
  } pixel_stream_t;

endpackage
