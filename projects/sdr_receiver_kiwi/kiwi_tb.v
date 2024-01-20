/* # ########################################################################
# Copyright (C) 2019, Xilinx Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ######################################################################## */

`timescale 1ns / 1ps

module tb;
    reg tb_ACLK;
    reg adc_ACLK;
    reg tb_ARESETn;
   
    wire temp_clk;
    wire temp_rstn;
    wire [15:0] adc_data;
   
    reg [31:0] read_data;
    wire [3:0] leds;
    reg resp;

    integer i;
    reg [15:0] sin_table_45MHz [0:255]; // 16-bit sine lookup table for 45MHz
    reg [15:0] sin_table_5MHz [0:63];    // 16-bit sine lookup table for 5MHz
    reg [7:0] phase_45MHz;
    reg [5:0] phase_5MHz;

    initial 
    begin       
        tb_ACLK = 1'b0;
        adc_ACLK = 1'b0;
        phase_45MHz = 0;
        phase_5MHz = 0;

        for (i = 0; i <= 255; i = i + 1) begin
            sin_table_45MHz[i] = $signed(16385 * $sin(i * 2 * 3.14159 / 256)); // Adjust amplitude as needed
        end

        for (i = 0; i <= 63; i = i + 1) begin
            sin_table_5MHz[i] = $signed(16385 * $sin(i * 2 * 3.14159 / 64)); // Adjust amplitude as needed
        end
    end
    
    //------------------------------------------------------------------------
    // Simple Clock Generator
    //------------------------------------------------------------------------

    // 125Mhz    
    always #8 tb_ACLK = !tb_ACLK;
    always #8 adc_ACLK = !adc_ACLK;


    assign adc_data = sin_table_45MHz[phase_45MHz] + sin_table_5MHz[phase_5MHz];
        
    always @ (posedge adc_ACLK) begin
        // Increment phases
        phase_45MHz <= phase_45MHz + 1;
        phase_5MHz <= phase_5MHz + 1;
    end

    reg[31:0]  intermediate_result;
    initial
    begin
    
        $display ("running the tb");
        
        tb_ARESETn = 1'b0;
        repeat(20)@(posedge tb_ACLK);        
        tb_ARESETn = 1'b1;
        @(posedge tb_ACLK);
        
        #10
        repeat(5) @(posedge tb_ACLK);

        //Reset the PL
        tb.zynq_sys.system_i.ps_0.inst.fpga_soft_reset(32'h1); #10
        tb.zynq_sys.system_i.ps_0.inst.fpga_soft_reset(32'h0); #10
		#2000

        tb.zynq_sys.system_i.ps_0.inst.write_data(32'h40000000, 2, 16'b0000, resp);         #10

        // Set Freq of RX0-7
        for (i = 0; i < 8; i = i + 1) begin
            intermediate_result = 45.0e6/ 125.0e6 * (1 << 30) + 0.5;
            tb.zynq_sys.system_i.ps_0.inst.write_data(32'h40000004 + i * 4, 4, intermediate_result, resp);
        end

        // Set Freq of WF
        intermediate_result = 45.0e6/ 125.0e6 * (1 << 30) + 0.5;
        tb.zynq_sys.system_i.ps_0.inst.write_data(32'h40000024, 4, intermediate_result, resp); #10
        // Set Decimate of WF
        tb.zynq_sys.system_i.ps_0.inst.write_data(32'h40000028, 4, 8, resp);                  #10

        tb.zynq_sys.system_i.ps_0.inst.write_data(32'h4000002c, 4, intermediate_result, resp); #10
        // Set Decimate of WF
        tb.zynq_sys.system_i.ps_0.inst.write_data(32'h40000030, 4, 16, resp);                  #10

        // Reset RX
        tb.zynq_sys.system_i.ps_0.inst.write_data(32'h40000000, 2, 16'b1111, resp);         #10

		#80000
        // Read back fifo count
        tb.zynq_sys.system_i.ps_0.inst.read_data(32'h41000000, 4, read_data, resp);
        if(read_data != 32'h0) begin
           $display ("RX FIFO Test PASSED");
        end
        else begin
           $display ("RX FIFO Test FAILED");
        end

        // Read back fifo count
        tb.zynq_sys.system_i.ps_0.inst.read_data(32'h41000004, 4, read_data,resp);

        if(read_data != 32'h0) begin
           $display ("WF0 FIFO Test PASSED: %d", read_data);
        end
        else begin
           $display ("WF0 FIFO Test FAILED");
        end

        tb.zynq_sys.system_i.ps_0.inst.read_data(32'h41000008, 4, read_data,resp);
        if(read_data != 32'h0) begin
           $display ("WF1 FIFO Test PASSED: %d", read_data);
        end
        else begin
           $display ("WF1 FIFO Test FAILED");
        end

        $display ("Simulation completed");
        $stop;
    end

    assign temp_clk = tb_ACLK;
    assign temp_rstn = tb_ARESETn;
   
    assign temp_adc_clk_p = adc_ACLK;
    assign temp_adc_clk_n = !adc_ACLK;
  
system_wrapper zynq_sys
   (.DDR_addr(),
    .DDR_ba(),
    .DDR_cas_n(),
    .DDR_ck_n(),
    .DDR_ck_p(),
    .DDR_cke(),
    .DDR_cs_n(),
    .DDR_dm(),
    .DDR_dq(),
    .DDR_dqs_n(),
    .DDR_dqs_p(),
    .DDR_odt(),
    .DDR_ras_n(),
    .DDR_reset_n(),
    .DDR_we_n(),
    .FIXED_IO_ddr_vrn(),
    .FIXED_IO_ddr_vrp(),
    .FIXED_IO_mio(),
    .FIXED_IO_ps_clk(temp_clk),
    .FIXED_IO_ps_porb(temp_rstn ),
    .FIXED_IO_ps_srstb(temp_rstn),
    .adc_clk_n_i(temp_adc_clk_n),
    .adc_clk_p_i(temp_adc_clk_p),
    .adc_csn_o(),
    .adc_dat_a_i(adc_data),
    .adc_dat_b_i(),
    .adc_enc_n_o(),
    .adc_enc_p_o(),
    .dac_clk_o(),
    .dac_dat_o(),
    .dac_pwm_o(),
    .dac_rst_o(),
    .dac_sel_o(),
    .dac_wrt_o(),
    .exp_n_tri_io(),
    .exp_p_tri_io(),
    .led_o()    
    
    );

endmodule

