# Create xlconstant
cell xilinx.com:ip:xlconstant const_0 {
  CONST_WIDTH 1
  CONST_VAL 0
}

cell xilinx.com:ip:xlconstant const_1 {
  CONST_WIDTH 1
  CONST_VAL 1
}

cell pavel-demin:user:port_slicer selector_slice_0 {
  DIN_WIDTH 8 DIN_FROM 0 DIN_TO 0
}

for {set i 0} {$i <= 3} {incr i} {

  # Create port_slicer, share reset bit with RX
  cell pavel-demin:user:port_slicer rst_slice_$i {
    DIN_WIDTH 8 DIN_FROM [expr $i + 1] DIN_TO [expr $i + 1]
  }

  # Create port_selector, only channel 0 IQ has selector
  if {[expr {$i == 0}]} {
    cell pavel-demin:user:port_selector selector_$i {
      DOUT_WIDTH 16
    } {
      cfg selector_slice_0/dout
      din /adc_0/m_axis_tdata
    }
  } else {
    cell pavel-demin:user:port_selector selector_$i {
      DOUT_WIDTH 16
    } {
      cfg const_0/dout
      din /adc_0/m_axis_tdata
    }
  }

  # Create port_slicer for phase
  cell pavel-demin:user:port_slicer slice_[expr $i * 2] {
    DIN_WIDTH 256 DIN_FROM [expr 64 * $i + 31] DIN_TO [expr 64 * $i]
  }

  # Create port_slicer for cic
  cell pavel-demin:user:port_slicer slice_[expr $i * 2 + 1] {
    DIN_WIDTH 256 DIN_FROM [expr 64 * $i + 47] DIN_TO [expr 64 * $i + 32]
  }

  # Create axis_constant
  cell pavel-demin:user:axis_constant phase_$i {
    AXIS_TDATA_WIDTH 32
  } {
    cfg_data slice_[expr $i * 2]/dout
    aclk /pll_0/clk_out1
  }

  # Create dds_compiler
  cell xilinx.com:ip:dds_compiler dds_$i {
    DDS_CLOCK_RATE 125
    SPURIOUS_FREE_DYNAMIC_RANGE 120
    FREQUENCY_RESOLUTION 0.2
    PHASE_INCREMENT Streaming
    HAS_PHASE_OUT false
    PHASE_WIDTH 30
    OUTPUT_WIDTH 24
    DSP48_USE Minimal
    NEGATIVE_SINE true
  } {
    S_AXIS_PHASE phase_$i/M_AXIS
    aclk /pll_0/clk_out1
  }
}

for {set i 0} {$i <= 7} {incr i} {

  # Create axis_variable
  cell pavel-demin:user:axis_variable rate_$i {
    AXIS_TDATA_WIDTH 16
  } {
    cfg_data slice_[expr ($i / 2) * 2 + 1]/dout
    aclk /pll_0/clk_out1
    aresetn /rst_0/peripheral_aresetn
  }

  # Create port_slicer
  cell pavel-demin:user:port_slicer dds_slice_$i {
    DIN_WIDTH 48 DIN_FROM [expr 24 * ($i % 2) + 23] DIN_TO [expr 24 * ($i % 2)]
  } {
    din dds_[expr $i / 2]/m_axis_data_tdata
  }

  # Create multipler
  cell xilinx.com:ip:mult_gen:12.0 mult_$i {
    PortAWidth.VALUE_SRC USER
    PortBWidth.VALUE_SRC USER
    Use_Custom_Output_Width true
    OutputWidthHigh 39
    OutputWidthLow 16
    PipeStages 4
    PortAWidth 24
    PortBWidth 16
    Multiplier_Construction Use_Mults
  } {
    A dds_slice_$i/dout
    B selector_[expr $i / 2]/dout
    CLK /pll_0/clk_out1
  }


  # Create cic_compiler
  cell pavel-demin:user:kiwi_wf_cic cic_$i {
  } {
    s_axis_data_tdata mult_$i/P
    s_axis_data_tvalid const_1/dout
    S_AXIS_CONFIG rate_$i/M_AXIS
    aclk /pll_0/clk_out1
    aresetn /rst_0/peripheral_aresetn
  }
}

for {set i 0} {$i <= 3} {incr i} {
  # Create axis_combiner
  cell  xilinx.com:ip:axis_combiner comb_$i {
    TDATA_NUM_BYTES.VALUE_SRC USER
    TDATA_NUM_BYTES 2
    NUM_SI 2
  } {
    S00_AXIS cic_[expr $i * 2]/M_AXIS_DATA
    S01_AXIS cic_[expr $i * 2 + 1]/M_AXIS_DATA
    aclk /pll_0/clk_out1
    aresetn /rst_0/peripheral_aresetn
  }

  # Create axis_fifo
  cell pavel-demin:user:axis_fifo fifo_$i {
    S_AXIS_TDATA_WIDTH 32
    M_AXIS_TDATA_WIDTH 32
    WRITE_DEPTH 4096
    ALWAYS_READY TRUE
  } {
    S_AXIS comb_$i/M_AXIS
    aclk /pll_0/clk_out1
    aresetn rst_slice_$i/dout
  }
}