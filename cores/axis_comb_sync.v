module axis_comb_sync #
(
    parameter AXIS0_WIDTH = 16,
    parameter AXIS1_WIDTH = 16
)
(
    input wire aclk,
    input wire aresetn,

    input  wire [AXIS0_WIDTH - 1 :0 ] s00_axis_tdata,
    input  wire                       s00_axis_tvalid,
    output wire                       s00_axis_tready,

    input  wire [AXIS1_WIDTH - 1 :0 ] s01_axis_tdata,
    input  wire                       s01_axis_tvalid,
    output wire                       s01_axis_tready,

    output wire [AXIS0_WIDTH + AXIS1_WIDTH - 1 :0 ] m_axis_tdata,
    output wire                       m_axis_tvalid,
    input  wire                       m_axis_tready
);

reg [AXIS0_WIDTH + AXIS1_WIDTH - 1 :0 ] axis_tdata_reg;
reg m_tvalid_reg;
reg s_tready_reg;

assign s00_axis_tready = s_tready_reg;
assign s01_axis_tready = s_tready_reg;
assign m_axis_tvalid  = m_tvalid_reg;
assign m_axis_tdata   = axis_tdata_reg;

always @ (posedge aclk or negedge aresetn)
    if(~aresetn)
        m_tvalid_reg <= 1'b0;
    else if(s00_axis_tvalid && s01_axis_tvalid)
        m_tvalid_reg <= 1'b1;
    else if(m_axis_tready)
        m_tvalid_reg <= 1'b0;

always @ (posedge aclk or negedge aresetn)
    if(~aresetn)
        s_tready_reg <= 1'b0;
    else
        s_tready_reg <= m_axis_tready;

always @ (posedge aclk)
    axis_tdata_reg <= {s01_axis_tdata,s00_axis_tdata};


endmodule