# Create clk_wiz
cell xilinx.com:ip:clk_wiz pll_0 {
  PRIMITIVE PLL
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 122.88
  PRIM_SOURCE Differential_clock_capable_pin
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 122.88
  CLKOUT2_USED true
  CLKOUT2_REQUESTED_OUT_FREQ 245.76
  CLKOUT2_REQUESTED_PHASE 157.5
  CLKOUT3_USED true
  CLKOUT3_REQUESTED_OUT_FREQ 245.76
  CLKOUT3_REQUESTED_PHASE 202.5
  USE_RESET false
} {
  clk_in1_p adc_clk_p_i
  clk_in1_n adc_clk_n_i
}

# Create processing_system7
cell xilinx.com:ip:processing_system7 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
} {
  M_AXI_GP0_ACLK pll_0/clk_out1
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
}

# ADC

# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc adc_0 {
  ADC_DATA_WIDTH 16
} {
  aclk pll_0/clk_out1
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# DAC

# Create axis_red_pitaya_dac
cell pavel-demin:user:axis_red_pitaya_dac dac_0 {
  DAC_DATA_WIDTH 14
} {
  aclk pll_0/clk_out1
  ddr_clk pll_0/clk_out2
  wrt_clk pll_0/clk_out3
  locked pll_0/locked
  dac_clk dac_clk_o
  dac_rst dac_rst_o
  dac_sel dac_sel_o
  dac_wrt dac_wrt_o
  dac_dat dac_dat_o
}

# CFG

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register cfg_0 {
  CFG_DATA_WIDTH 352
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# RX 0

# Create port_slicer
cell pavel-demin:user:port_slicer rst_slice_0 {
  DIN_WIDTH 352 DIN_FROM 7 DIN_TO 0
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_0 {
  DIN_WIDTH 352 DIN_FROM 319 DIN_TO 32
} {
  din cfg_0/cfg_data
}

module rx_0 {
  source projects/sdr_transceiver_ft8_122_88/rx.tcl
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
  slice_9/din cfg_slice_0/dout
  slice_10/din cfg_slice_0/dout
  slice_11/din cfg_slice_0/dout
  slice_12/din cfg_slice_0/dout
  slice_13/din cfg_slice_0/dout
  slice_14/din cfg_slice_0/dout
  slice_15/din cfg_slice_0/dout
  slice_16/din cfg_slice_0/dout
}

# TX 0

# Create port_slicer
cell pavel-demin:user:port_slicer rst_slice_1 {
  DIN_WIDTH 352 DIN_FROM 15 DIN_TO 8
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_1 {
  DIN_WIDTH 352 DIN_FROM 351 DIN_TO 320
} {
  din cfg_0/cfg_data
}

module tx_0 {
  source projects/sdr_transceiver_ft8_122_88/tx.tcl
} {
  slice_0/din rst_slice_1/dout
  slice_1/din cfg_slice_1/dout
  slice_2/din cfg_slice_1/dout
  zeroer_0/M_AXIS dac_0/S_AXIS
}

# GPIO, PPS and level measurement

module common_0 {
  source projects/common_tools/block_design.tcl
}

# STS

# Create dna_reader
cell pavel-demin:user:dna_reader dna_0 {} {
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create xlconcat
cell xilinx.com:ip:xlconcat concat_0 {
  NUM_PORTS 10
  IN0_WIDTH 32
  IN1_WIDTH 64
  IN2_WIDTH 16
  IN3_WIDTH 16
  IN4_WIDTH 16
  IN5_WIDTH 16
  IN6_WIDTH 16
  IN7_WIDTH 16
  IN8_WIDTH 16
  IN9_WIDTH 16
} {
  In0 const_0/dout
  In1 dna_0/dna_data
  In2 rx_0/fifo_generator_0/rd_data_count
  In3 rx_0/fifo_generator_1/rd_data_count
  In4 rx_0/fifo_generator_2/rd_data_count
  In5 rx_0/fifo_generator_3/rd_data_count
  In6 rx_0/fifo_generator_4/rd_data_count
  In7 rx_0/fifo_generator_5/rd_data_count
  In8 rx_0/fifo_generator_6/rd_data_count
  In9 rx_0/fifo_generator_7/rd_data_count
}

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register sts_0 {
  STS_DATA_WIDTH 224
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data concat_0/dout
}

addr 0x40000000 4K sts_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40001000 4K cfg_0/S_AXI /ps_0/M_AXI_GP0

for {set i 0} {$i <= 7} {incr i} {

  addr 0x400[format %02X [expr $i + 2]]000 4K rx_0/reader_$i/S_AXI /ps_0/M_AXI_GP0

}

addr 0x40012000 4K tx_0/writer_0/S_AXI /ps_0/M_AXI_GP0
