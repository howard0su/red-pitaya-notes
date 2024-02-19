`timescale 1 ns / 1 ps

module axis_rdtsc #
(
  parameter integer AXIS_TDATA_WIDTH = 64,
  parameter integer CNTR_WIDTH = 48
)
(
  // System signals
  input  wire                        aclk,
  input  wire                        aresetn,

  // Master side
  output wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
  output wire                        m_axis_tvalid
);

  reg [CNTR_WIDTH-1:0] int_cntr_reg;

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_cntr_reg <= {(CNTR_WIDTH){1'b0}};
    end
    else
    begin
      int_cntr_reg <= int_cntr_reg + 1'b1;
    end
  end

  assign m_axis_tdata = {{(AXIS_TDATA_WIDTH-CNTR_WIDTH){1'b0}}, int_cntr_reg};
  assign m_axis_tvalid = 1'b1;

endmodule
