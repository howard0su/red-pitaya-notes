
cell xilinx.com:ip:v_frmbuf_rd v_frmbuf_rd_0 {
    SAMPLES_PER_CLOCK 1
    MAX_COLS 800
    MAX_ROWS 480
}
{
    ap_rst_n /rst_0/peripheral_aresetn
}

cell xilinx.com:ip:mipi_dsi_tx_subsystem mipi_dsi_tx_subsystem_0
{
    SupportLevel 1
}
{
    s_axis v_frmbuf_rd_0/m_axis_video
    s_axis_areasetn /rst_0/peripheral_aresetn
}

cell xilinx.com:ip:xlconcat concat_0
{
    PORT 4
    IN0_WIDTH 1
    IN1_WIDTH 1
    IN2_WIDTH 1
    IN3_WIDTH 1
}
{
    In0 mipi_dsi_tx_subsystem_0/mipi_phy_if_clk_hs_n
    In1 mipi_dsi_tx_subsystem_0/mipi_phy_if_clk_hs_p
    In2 mipi_dsi_tx_subsystem_0/mipi_phy_if_data_hs_n
    In3 mipi_dsi_tx_subsystem_0/mipi_phy_if_data_hs_p
}

addr 0x43c00000 64K v_frmbuf_rd_0/S_AXI /ps_0/M_AXI_GP0
addr 0x43c10000 64K v_frmbuf_rd_0/s_axi_CTRL /ps_0/M_AXI_GP0