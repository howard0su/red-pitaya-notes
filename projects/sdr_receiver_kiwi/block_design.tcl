# Create clk_wiz
cell xilinx.com:ip:clk_wiz pll_0 {
  PRIMITIVE PLL
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 125.0
  PRIM_SOURCE Differential_clock_capable_pin
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 125.0
  CLKOUT2_USED false
  CLKOUT2_REQUESTED_OUT_FREQ 250.0
  CLKOUT2_REQUESTED_PHASE 157.5
  CLKOUT3_USED false
  CLKOUT3_REQUESTED_OUT_FREQ 250.0
  CLKOUT3_REQUESTED_PHASE 202.5
  USE_RESET false
} {
  clk_in1_p adc_clk_p_i
  clk_in1_n adc_clk_n_i
}

# Create processing_system7
cell xilinx.com:ip:processing_system7 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
  PCW_USE_M_AXI_GP1 1
} {
  M_AXI_GP0_ACLK pll_0/clk_out1
  M_AXI_GP1_ACLK pll_0/clk_out1
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create xlconstant
cell xilinx.com:ip:xlconstant const_0

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset rst_0 {} {
  ext_reset_in const_0/dout
  dcm_locked pll_0/locked
  slowest_sync_clk pll_0/clk_out1
}

# ADC

# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc adc_0 {
  ADC_DATA_WIDTH 14
} {
  aclk pll_0/clk_out1
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# HUB

# Address Space arrangement
# Write Width: (CFG)
#   RESET: 0 -  31, 32bits -> reset
#   RX:  32  - 287, 256btis -> 8 channel freq （8*32)
#   WF:  288 - 543 , 256bits -> 4 channel freq (4 * 32) + 4 channel cic step ( 4 * 32)
#  Total 544 bits
# Read Width: (STS)
#   RX FIFO: 0 - 31, 32bits
#   WF CHANNEL0-3: 32-159, 32bits * 4 = 128bits.
#  Total 160bits

# Create axi_hub
cell pavel-demin:user:axi_hub hub_0 {
  CFG_DATA_WIDTH 544
  STS_DATA_WIDTH 160
} {
  S_AXI ps_0/M_AXI_GP0
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# RX 0

# Create port_slicer
cell pavel-demin:user:port_slicer rst_slice_0 {
  DIN_WIDTH 544 DIN_FROM 7 DIN_TO 0
} {
  din hub_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_0 {
  DIN_WIDTH 544 DIN_FROM 287 DIN_TO 32
} {
  din hub_0/cfg_data
}

module rx_0 {
  source projects/sdr_receiver_kiwi/rx.tcl
} {
  slice_0/din rst_slice_0/dout
  slice_1/din cfg_slice_0/dout
  slice_2/din cfg_slice_0/dout
  slice_3/din cfg_slice_0/dout
  slice_4/din cfg_slice_0/dout
  slice_5/din cfg_slice_0/dout
  slice_6/din cfg_slice_0/dout
  slice_7/din cfg_slice_0/dout
  slice_8/din cfg_slice_0/dout
  conv_2/M_AXIS hub_0/S00_AXIS
}

# Waterflow moduless

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_1 {
  DIN_WIDTH 544 DIN_FROM 543 DIN_TO 287
} {
  din hub_0/cfg_data
}

module wf_0 {
  source projects/sdr_receiver_kiwi/wf.tcl
} {
  rst_slice_0/din rst_slice_0/dout
  rst_slice_1/din rst_slice_0/dout
  rst_slice_2/din rst_slice_0/dout
  rst_slice_3/din rst_slice_0/dout

  slice_1/din cfg_slice_1/dout
  slice_2/din cfg_slice_1/dout
  slice_3/din cfg_slice_1/dout
  slice_4/din cfg_slice_1/dout

  fifo_0/M_AXIS hub_0/S01_AXIS
  fifo_1/M_AXIS hub_0/S02_AXIS
  fifo_2/M_AXIS hub_0/S03_AXIS
  fifo_3/M_AXIS hub_0/S04_AXIS
}

# Create xlconcat
cell xilinx.com:ip:xlconcat concat_0 {
  NUM_PORTS 5
  IN0_WIDTH 32
  IN1_WIDTH 32
  IN2_WIDTH 32
  IN3_WIDTH 32
  IN4_WIDTH 32
} {
  In0 rx_0/fifo_0/read_count
  In1 wf_0/fifo_0/read_count
  In2 wf_0/fifo_1/read_count
  In3 wf_0/fifo_2/read_count
  In4 wf_0/fifo_3/read_count

  dout hub_0/sts_data
}


# GPIO, PPS and level measurement

module common_0 {
  source projects/common_tools/block_design.tcl
}
