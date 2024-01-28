`timescale 1 ns / 1 ps

module kiwi_wf_cic # (
    parameter STAGES = 5,
    parameter DECIMATION = -8192,  
    parameter IN_WIDTH = 24,
    parameter GROWTH = 65,
    parameter OUT_WIDTH = 16,
    parameter MD = 18
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
  input  wire [MD-1:0]       s_axis_config_tdata,
  input  wire                      s_axis_config_tvalid,

  // Master side
  output wire [OUT_WIDTH-1:0]      m_axis_data_tdata,
  output wire                      m_axis_data_tvalid,
  input  wire                      m_axis_data_tready
);



reg [MD - 1:0] decim;
reg ready_flag;
wire kiwi_cic_d_valid;
wire [OUT_WIDTH-1:0] kiwi_cic_d_data;
reg [OUT_WIDTH-1:0] data_reg;

assign s_axis_data_tready = 1'b1;
assign s_axis_config_tready = 1'b1;

assign m_axis_data_tvalid = ready_flag;
assign m_axis_data_tdata = data_reg;

always @ (posedge aclk)
    if(~aresetn)
        decim <= 32;
    else if(s_axis_config_tvalid)
        decim <= s_axis_config_tdata[MD - 1:0];
        
always @ (posedge aclk)
    if(~aresetn)
        ready_flag <= 0;
    else if(kiwi_cic_d_valid == 1'b1)
        ready_flag <= 1'b1;
    else if(m_axis_data_tready == 1'b1)
        ready_flag <= 0;
        
always @ (posedge aclk)
    if(~aresetn)
        data_reg <= 0;
    else if(kiwi_cic_d_valid == 1'b1)
        data_reg <= kiwi_cic_d_data;
    

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
	.out_strobe     (kiwi_cic_d_valid),
	.in_data        (s_axis_data_tdata),
	.out_data       (kiwi_cic_d_data)
);

endmodule
