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
  dcm_locked pll_0/locked
  slowest_sync_clk pll_0/clk_out1
}

# HUB

# Address Space arrangement
# Write Width: (CFG)
#   RESET: 0 - 15, 16bits -> reset (bit 0 : rx, bit 1-4, wf, bit 8: pps)
#   SELECTOR: 16-31, 16bits -> bit0: 1->gen, 0->adc
#   RX:  32  - 287, 256btis -> 8 channel freq （8*32)
#   WF:  288 - 543, 256bits -> 4 channel freq (4 * 32) + 4 channel cic step ( 4 * 32)
#   GEN: 544 - 575, 32bits -> Gen Freq(32bits)
#  Total 576 bits
# Read Width: (STS)
#   RX FIFO: 0 - 31, 32bits
#   WF CHANNEL0-3: 32-159, 32bits * 4 = 128bits.
#   PPS FIFO: 160-191, 32bits
#   DNA: 192 - 255, 64bits
#  Total 256bits

# Create axi_hub
cell pavel-demin:user:axi_hub hub_0 {
  CFG_DATA_WIDTH 576
  STS_DATA_WIDTH 256
} {
  S_AXI ps_0/M_AXI_GP0
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Signal Generation
cell pavel-demin:user:port_slicer gen_freq_slice {
  DIN_WIDTH 576 DIN_FROM 575 DIN_TO 544
} {
  din hub_0/cfg_data
}

cell pavel-demin:user:axis_constant gen_phase {
  AXIS_TDATA_WIDTH 32
} {
  cfg_data gen_freq_slice/dout
  aclk /pll_0/clk_out1
}

cell xilinx.com:ip:dds_compiler dds_gen {
    DDS_CLOCK_RATE 125
    SPURIOUS_FREE_DYNAMIC_RANGE 96
    FREQUENCY_RESOLUTION 1
    PHASE_INCREMENT Streaming
    OUTPUT_SELECTION SINE
    HAS_PHASE_OUT false
    PHASE_WIDTH 30
    OUTPUT_WIDTH 16
    DSP48_USE Minimal
    NEGATIVE_SINE false
  } {
    S_AXIS_PHASE gen_phase/M_AXIS
    aclk /pll_0/clk_out1
  }

# ADC
# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc adc_0 {
  ADC_DATA_WIDTH 16
} {
  aclk pll_0/clk_out1
  adc_dat_a adc_dat_a_i
  adc_dat_b dds_gen/m_axis_data_tdata
  adc_csn adc_csn_o
}

# RX 0

# Create port_slicer
cell pavel-demin:user:port_slicer rst_slice {
  DIN_WIDTH 576 DIN_FROM 7 DIN_TO 0
} {
  din hub_0/cfg_data
}

cell pavel-demin:user:port_slicer select_slice {
  DIN_WIDTH 576 DIN_FROM 15 DIN_TO 8
} {
  din hub_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_rx {
  DIN_WIDTH 576 DIN_FROM 287 DIN_TO 32
} {
  din hub_0/cfg_data
}

module rx_0 {
  source projects/sdr_receiver_kiwi/rx.tcl
} {
  rst_slice_0/din rst_slice/dout
  selector_slice_0/din select_slice/dout
  slice_1/din cfg_slice_rx/dout
  slice_2/din cfg_slice_rx/dout
  slice_3/din cfg_slice_rx/dout
  slice_4/din cfg_slice_rx/dout
  slice_5/din cfg_slice_rx/dout
  slice_6/din cfg_slice_rx/dout
  slice_7/din cfg_slice_rx/dout
  slice_8/din cfg_slice_rx/dout
  conv_2/M_AXIS hub_0/S00_AXIS
}

# Waterflow moduless

# Create port_slicer
cell pavel-demin:user:port_slicer cfg_slice_wf {
  DIN_WIDTH 576 DIN_FROM 543 DIN_TO 288
} {
  din hub_0/cfg_data
}

module wf_0 {
  source projects/sdr_receiver_kiwi/wf.tcl
} {
  rst_slice_0/din rst_slice/dout
  rst_slice_1/din rst_slice/dout
  rst_slice_2/din rst_slice/dout
  rst_slice_3/din rst_slice/dout

  slice_0/din cfg_slice_wf/dout
  slice_1/din cfg_slice_wf/dout
  slice_2/din cfg_slice_wf/dout
  slice_3/din cfg_slice_wf/dout
  slice_4/din cfg_slice_wf/dout
  slice_5/din cfg_slice_wf/dout
  slice_6/din cfg_slice_wf/dout
  slice_7/din cfg_slice_wf/dout

  conv_0/M_AXIS hub_0/S01_AXIS
  conv_1/M_AXIS hub_0/S02_AXIS
  conv_2/M_AXIS hub_0/S03_AXIS
  conv_3/M_AXIS hub_0/S04_AXIS
}


# PPS
cell pavel-demin:user:port_slicer rst_slice_pps {
  DIN_WIDTH 576 DIN_FROM 8 DIN_TO 8
} {
  din hub_0/cfg_data
}

# Delete input/output port
delete_bd_objs [get_bd_ports /exp_n_tri_io]

# Create input port
create_bd_port -dir I -from 3 -to 0 exp_n_tri_io

# Create port_slicer
cell pavel-demin:user:port_slicer pps_slice_0 {
  DIN_WIDTH 4 DIN_FROM 3 DIN_TO 3
} {
  din /exp_n_tri_io
  dout /ps_0/GPIO_I
}

# Create axis_pps_counter
cell pavel-demin:user:axis_pps_counter cntr_0 {
  AXIS_TDATA_WIDTH 32
  CNTR_WIDTH 32
} {
  pps_data pps_slice_0/dout
  aclk /pll_0/clk_out1
  aresetn rst_slice_pps/dout
}

# Create axis_fifo
cell pavel-demin:user:axis_fifo fifo_0 {
  S_AXIS_TDATA_WIDTH 32
  M_AXIS_TDATA_WIDTH 32
  WRITE_DEPTH 1024
} {
  S_AXIS cntr_0/M_AXIS
  M_AXIS hub_0/S05_AXIS
  aclk /pll_0/clk_out1
  aresetn rst_slice_pps/dout
}

cell pavel-demin:user:dna_reader dna_0 {} {
  aclk /pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create xlconcat
cell xilinx.com:ip:xlconcat concat_0 {
  NUM_PORTS 7
  IN0_WIDTH 32
  IN1_WIDTH 32
  IN2_WIDTH 32
  IN3_WIDTH 32
  IN4_WIDTH 32
  IN5_WIDTH 32
  IN6_WIDTH 64
} {
  In0 rx_0/fifo_0/read_count
  In1 wf_0/fifo_0/read_count
  In2 wf_0/fifo_1/read_count
  In3 wf_0/fifo_2/read_count
  In4 wf_0/fifo_3/read_count
  In5 fifo_0/read_count
  In6 dna_0/dna_data

  dout hub_0/sts_data
}
