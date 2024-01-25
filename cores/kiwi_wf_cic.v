`timescale 1ns/1ns

module kiwi_wf_cic # (
    parameter STAGES = 5,
    parameter DECIMATION = -8192,  
    parameter IN_WIDTH = 24,
    parameter GROWTH = 65,
    parameter OUT_WIDTH = 16
)
(
  // System signals
  input  wire                      aclk,
  input  wire                      aresetn,

  // Slave side
  output wire                      s_axis_data_tready,
  input  wire [IN_WIDTH-1:0]       s_axis_data_tdata,
  input  wire                      s_axis_data_tvalid,

  // Config side
  output wire                      s_axis_config_tready,
  input  wire [IN_WIDTH-1:0]       s_axis_config_tdata,
  input  wire                      s_axis_config_tvalid,

  // Master side
  output wire [OUT_WIDTH-1:0]      m_axis_data_tdata,
  output wire                      m_axis_data_tvalid
);

localparam MD = 18;

reg [MD - 1:0] decim;

assign s_axis_data_tready = 1'b1;
assign s_axis_config_tready = 1'b1;

always @ (posedge aclk)
    if(~aresetn)
        decim <= 32;
    else if(s_axis_config_tvalid)
        decim <= s_axis_config_tdata[MD - 1:0];

cic_prune_var # (
    .STAGES(STAGES),
    .DECIMATION(DECIMATION),
    .IN_WIDTH(IN_WIDTH),
    .GROWTH(GROWTH),
    .OUT_WIDTH(OUT_WIDTH)
)
kiwi_wf_fir
(
	.clock          (aclk),
	.reset          (~aresetn),
	.decimation     (decim),
	.in_strobe      (s_axis_data_tvalid),
	.out_strobe     (m_axis_data_tvalid),
	.in_data        (s_axis_data_tdata),
	.out_data       (m_axis_data_tdata)
);

endmodule
