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
  CLKOUT2_REQUESTED_PHASE -90.0
  CLKOUT3_USED true
  CLKOUT3_REQUESTED_OUT_FREQ 245.76
  CLKOUT3_REQUESTED_PHASE -45.0
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

# XADC

# Create xadc_wiz
cell xilinx.com:ip:xadc_wiz xadc_0 {
  DCLK_FREQUENCY 143
  ADC_CONVERSION_RATE 100
  XADC_STARUP_SELECTION independent_adc
  CHANNEL_ENABLE_VAUXP0_VAUXN0 true
  CHANNEL_ENABLE_VAUXP1_VAUXN1 true
  CHANNEL_ENABLE_VAUXP8_VAUXN8 true
  CHANNEL_ENABLE_VAUXP9_VAUXN9 true
  CHANNEL_ENABLE_VP_VN true
} {
  Vp_Vn Vp_Vn
  Vaux0 Vaux0
  Vaux1 Vaux1
  Vaux8 Vaux8
  Vaux9 Vaux9
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
  s_axis_tvalid const_0/dout
}

# CFG

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register cfg_0 {
  CFG_DATA_WIDTH 352
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# GPIO

# Delete input/output port
delete_bd_objs [get_bd_ports exp_p_tri_io]

# Create output port
create_bd_port -dir O -from 7 -to 0 exp_p_tri_io

# Create port_slicer
cell pavel-demin:user:port_slicer out_slice_0 {
  DIN_WIDTH 352 DIN_FROM 31 DIN_TO 24
} {
  din cfg_0/cfg_data
  dout exp_p_tri_io
}

# Delete input/output port
delete_bd_objs [get_bd_ports exp_n_tri_io]

# Create input/output port
create_bd_port -dir IO -from 3 -to 0 exp_n_tri_io

# Create gpio_debouncer
cell pavel-demin:user:gpio_debouncer gpio_0 {
  DATA_WIDTH 4
  CNTR_WIDTH 16
} {
  gpio_data exp_n_tri_io
  aclk pll_0/clk_out1
}

# Create util_vector_logic
cell xilinx.com:ip:util_vector_logic not_0 {
  C_SIZE 4
  C_OPERATION not
} {
  Op1 gpio_0/deb_data
}

# ALEX

# Create output port
create_bd_port -dir IO -from 3 -to 0 exp_n_alex

module alex {
  source projects/sdr_transceiver_emb/alex.tcl
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
  DIN_WIDTH 352 DIN_FROM 95 DIN_TO 32
} {
  din cfg_0/cfg_data
}

module rx_0 {
  source projects/sdr_transceiver_emb/rx.tcl
} {
  slice_0/din rst_slice_0/dout
  slice_1/din cfg_slice_0/dout
  slice_2/din cfg_slice_0/dout
}

# SP 0

# Create port_slicer
cell pavel-demin:user:port_slicer rst_slice_1 {
  DIN_WIDTH 352 DIN_FROM 7 DIN_TO 0
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_1 {
  DIN_WIDTH 352 DIN_FROM 223 DIN_TO 96
} {
  din cfg_0/cfg_data
}

module sp_0 {
  source projects/sdr_transceiver_emb/sp.tcl
} {
  slice_0/din rst_slice_1/dout
  slice_1/din rst_slice_1/dout
  slice_2/din cfg_slice_1/dout
  slice_3/din cfg_slice_1/dout
  slice_4/din cfg_slice_1/dout
  slice_5/din cfg_slice_1/dout
  slice_6/din cfg_slice_1/dout
}

# TX 0

# Create port_slicer
cell pavel-demin:user:port_slicer rst_slice_2 {
  DIN_WIDTH 352 DIN_FROM 15 DIN_TO 8
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_2 {
  DIN_WIDTH 352 DIN_FROM 287 DIN_TO 224
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer key_slice_0 {
  DIN_WIDTH 4 DIN_FROM 2 DIN_TO 2
} {
  din not_0/Res
}

module tx_0 {
  source projects/sdr_transceiver_emb/tx.tcl
} {
  slice_0/din rst_slice_2/dout
  slice_1/din cfg_slice_2/dout
  slice_2/din cfg_slice_2/dout
  slice_3/din cfg_slice_2/dout
  keyer_0/key_flag key_slice_0/dout
  mult_1/P dac_0/s_axis_tdata
}

# CODEC

# Create port_slicer
cell pavel-demin:user:port_slicer rst_slice_3 {
  DIN_WIDTH 352 DIN_FROM 23 DIN_TO 16
} {
  din cfg_0/cfg_data
}


# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_3 {
  DIN_WIDTH 352 DIN_FROM 351 DIN_TO 288
} {
  din cfg_0/cfg_data
}

module codec {
  source projects/sdr_transceiver_emb/codec.tcl
} {
  slice_0/din rst_slice_3/dout
  slice_1/din rst_slice_3/dout
  slice_2/din rst_slice_3/dout
  slice_3/din cfg_slice_3/dout
  slice_4/din cfg_slice_3/dout
  slice_5/din cfg_slice_3/dout
  keyer_0/key_flag key_slice_0/dout
  i2s_0/gpio_data exp_n_alex
  i2s_0/alex_data alex/alex_0/alex_data
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
  IN9_WIDTH 4
} {
  In0 const_0/dout
  In1 dna_0/dna_data
  In2 rx_0/fifo_generator_0/rd_data_count
  In3 rx_0/fifo_generator_1/rd_data_count
  In4 sp_0/fifo_generator_0/data_count
  In5 sp_0/fifo_generator_1/data_count
  In6 tx_0/fifo_generator_0/wr_data_count
  In7 codec/fifo_generator_0/data_count
  In8 codec/fifo_generator_1/data_count
  In9 not_0/Res
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

addr 0x40002000 4K alex/writer_0/S_AXI /ps_0/M_AXI_GP0

for {set i 0} {$i <= 1} {incr i} {

  addr 0x4000[format %X [expr $i + 3]]000 4K rx_0/reader_$i/S_AXI /ps_0/M_AXI_GP0

}

addr 0x40005000 4K tx_0/writer_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40006000 4K tx_0/writer_1/S_AXI /ps_0/M_AXI_GP0

addr 0x40007000 4K tx_0/switch_0/S_AXI_CTRL /ps_0/M_AXI_GP0

addr 0x40008000 4K sp_0/writer_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40009000 4K sp_0/reader_1/S_AXI /ps_0/M_AXI_GP0

addr 0x4000A000 4K codec/writer_0/S_AXI /ps_0/M_AXI_GP0

addr 0x4000B000 4K codec/writer_1/S_AXI /ps_0/M_AXI_GP0

addr 0x4000C000 4K codec/switch_0/S_AXI_CTRL /ps_0/M_AXI_GP0

addr 0x4000D000 4K codec/reader_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40020000 64K xadc_0/s_axi_lite /ps_0/M_AXI_GP0
