/*
--------------------------------------------------------------------------------
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.
You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.
--------------------------------------------------------------------------------
*/

// Copyright (c) 2008 Alex Shovkoplyas, VE3NEA
// Copyright (c) 2013 Phil Harman, VK6APH
// Copyright (c) 2014 John Seamons, ZL4VO/KF6VO


//
// Implements fixed and 2**n variable decimation (R).
//
// NB: when variable decimation is specified by .DECIMATION(<0) then .GROWTH() must
// specify for the largest expected decimation.
//
// Fixed differential delay (D) = 1
//

module cic_prune_var (
	input wire clock,
	input wire reset,
	input wire [MD-1:0] decimation,
	input wire in_strobe,
	output reg out_strobe,
	input wire signed [IN_WIDTH-1:0] in_data,
	output reg signed [OUT_WIDTH-1:0] out_data
	);

    // design parameters
    parameter STAGES = 5;
    parameter DECIMATION = -8192;  
    parameter IN_WIDTH = "required";
    parameter GROWTH = "required";
    parameter OUT_WIDTH = "required";
    
    localparam ACC_WIDTH = IN_WIDTH + GROWTH;
    
    parameter MD = 18;		// assumes excess counter bits get optimized away
    
    reg [MD-1:0] sample_no;
    initial sample_no = {MD{1'b0}};
    wire [MD-1:0] decim;
    
    generate
        if (DECIMATION < 0) begin assign decim = decimation; end	// variable
        if (DECIMATION > 0) begin assign decim = DECIMATION; end	// fixed
    endgenerate
    
    always @(posedge clock)
      if (in_strobe)
        begin
        if (sample_no == (decim-1))
          begin
          sample_no <= 0;
          out_strobe <= 1;
          end
        else
          begin
          sample_no <= sample_no + 1'b1;
          out_strobe <= 0;
          end
        end
      else
        out_strobe <= 0;
    
    reg signed [ACC_WIDTH-1:0] in;
    wire signed [OUT_WIDTH-1:0] out;
    
wire signed [88:0] integrator0_data;
wire signed [88:0] integrator1_data;
wire signed [88:0] integrator2_data;
wire signed [88:0] integrator3_data;
wire signed [88:0] integrator4_data;
wire signed [27:0] integrator5_data;
wire signed [27:0] comb0_data;
wire signed [22:0] comb1_data;
wire signed [21:0] comb2_data;
wire signed [20:0] comb3_data;
wire signed [19:0] comb4_data;
wire signed [19:0] comb5_data;

// important that "in" be declared signed by wrapper code
// so this assignment will sign-extend:
assign integrator0_data = in;

cic_integrator #(.WIDTH(89)) cic_integrator1_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator0_data[88 -:89]),	// trunc 0 bits (should always be zero)
	.out_data(integrator1_data)
);

cic_integrator #(.WIDTH(89)) cic_integrator2_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator1_data[88 -:89]),	// trunc 0 bits 
	.out_data(integrator2_data)
);

cic_integrator #(.WIDTH(89)) cic_integrator3_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator2_data[88 -:89]),	// trunc 0 bits 
	.out_data(integrator3_data)
);

cic_integrator #(.WIDTH(89)) cic_integrator4_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator3_data[88 -:89]),	// trunc 0 bits 
	.out_data(integrator4_data)
);

cic_integrator #(.WIDTH(28)) cic_integrator5_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator4_data[88 -:28]),	// trunc 61 bits 
	.out_data(integrator5_data)
);

assign comb0_data = integrator5_data;

cic_comb #(.WIDTH(23)) cic_comb1_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb0_data[27 -:23]),	// trunc 5 bits 
	.out_data(comb1_data)
);

cic_comb #(.WIDTH(22)) cic_comb2_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb1_data[22 -:22]),	// trunc 1 bits 
	.out_data(comb2_data)
);

cic_comb #(.WIDTH(21)) cic_comb3_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb2_data[21 -:21]),	// trunc 1 bits 
	.out_data(comb3_data)
);

cic_comb #(.WIDTH(20)) cic_comb4_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb3_data[20 -:20]),	// trunc 1 bits 
	.out_data(comb4_data)
);

cic_comb #(.WIDTH(20)) cic_comb5_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb4_data[19 -:20]),	// trunc 0 bits 
	.out_data(comb5_data)
);

assign out = comb5_data[19 -:16] + comb5_data[3];	// trunc 4 bits, rounding applied


    // pre-shift input data to top bits of max case sized (ACC_WIDTH) first integrator stage

	localparam GROWTH_R2	= STAGES * $clog2(2);
	localparam GROWTH_R4	= STAGES * $clog2(4);
	localparam GROWTH_R8	= STAGES * $clog2(8);
	localparam GROWTH_R16	= STAGES * $clog2(16);
	localparam GROWTH_R32	= STAGES * $clog2(32);
	localparam GROWTH_R64	= STAGES * $clog2(64);
	localparam GROWTH_R128	= STAGES * $clog2(128);
	localparam GROWTH_R256	= STAGES * $clog2(256);
	localparam GROWTH_R512	= STAGES * $clog2(512);
	localparam GROWTH_R1K	= STAGES * $clog2(1024);
	localparam GROWTH_R2K	= STAGES * $clog2(2048);
	localparam GROWTH_R4K	= STAGES * $clog2(4096);
	localparam GROWTH_R8K	= STAGES * $clog2(8192);
	localparam GROWTH_R16K	= STAGES * $clog2(16384);
	
	localparam ACC_R2		= IN_WIDTH + GROWTH_R2;
	localparam ACC_R4		= IN_WIDTH + GROWTH_R4;
	localparam ACC_R8		= IN_WIDTH + GROWTH_R8;
	localparam ACC_R16		= IN_WIDTH + GROWTH_R16;
	localparam ACC_R32		= IN_WIDTH + GROWTH_R32;
	localparam ACC_R64		= IN_WIDTH + GROWTH_R64;
	localparam ACC_R128		= IN_WIDTH + GROWTH_R128;
	localparam ACC_R256		= IN_WIDTH + GROWTH_R256;
	localparam ACC_R512		= IN_WIDTH + GROWTH_R512;
	localparam ACC_R1K		= IN_WIDTH + GROWTH_R1K;
	localparam ACC_R2K		= IN_WIDTH + GROWTH_R2K;
	localparam ACC_R4K		= IN_WIDTH + GROWTH_R4K;
	localparam ACC_R8K		= IN_WIDTH + GROWTH_R8K;
	localparam ACC_R16K		= IN_WIDTH + GROWTH_R16K;
	
    generate
        if (DECIMATION == -1)
        begin
        
        always @(posedge clock)
            in <= in_data;
        end
    endgenerate
    
    generate
        if (DECIMATION == -64)
        begin
        
        always @(posedge clock)
            case (decim)
                   1: in <= in_data;
                   2: in <= in_data << (ACC_WIDTH - ACC_R2);
                   4: in <= in_data << (ACC_WIDTH - ACC_R4);
                   8: in <= in_data << (ACC_WIDTH - ACC_R8);
                  16: in <= in_data << (ACC_WIDTH - ACC_R16);
                  32: in <= in_data << (ACC_WIDTH - ACC_R32);
                  64: in <= in_data << (ACC_WIDTH - ACC_R64);
             default: in <= in_data;
            endcase
        end
    endgenerate
    
    generate
        if (DECIMATION == -2048)
        begin
        
        always @(posedge clock)
            case (decim)
                   1: in <= in_data;
                   2: in <= in_data << (ACC_WIDTH - ACC_R2);
                   4: in <= in_data << (ACC_WIDTH - ACC_R4);
                   8: in <= in_data << (ACC_WIDTH - ACC_R8);
                  16: in <= in_data << (ACC_WIDTH - ACC_R16);
                  32: in <= in_data << (ACC_WIDTH - ACC_R32);
                  64: in <= in_data << (ACC_WIDTH - ACC_R64);
                 128: in <= in_data << (ACC_WIDTH - ACC_R128);
                 256: in <= in_data << (ACC_WIDTH - ACC_R256);
                 512: in <= in_data << (ACC_WIDTH - ACC_R512);
                1024: in <= in_data << (ACC_WIDTH - ACC_R1K);
                2048: in <= in_data << (ACC_WIDTH - ACC_R2K);
             default: in <= in_data;
            endcase
        end
    endgenerate
    
    generate
        if (DECIMATION == -4096)
        begin
        
        always @(posedge clock)
            case (decim)
                   1: in <= in_data;
                   2: in <= in_data << (ACC_WIDTH - ACC_R2);
                   4: in <= in_data << (ACC_WIDTH - ACC_R4);
                   8: in <= in_data << (ACC_WIDTH - ACC_R8);
                  16: in <= in_data << (ACC_WIDTH - ACC_R16);
                  32: in <= in_data << (ACC_WIDTH - ACC_R32);
                  64: in <= in_data << (ACC_WIDTH - ACC_R64);
                 128: in <= in_data << (ACC_WIDTH - ACC_R128);
                 256: in <= in_data << (ACC_WIDTH - ACC_R256);
                 512: in <= in_data << (ACC_WIDTH - ACC_R512);
                1024: in <= in_data << (ACC_WIDTH - ACC_R1K);
                2048: in <= in_data << (ACC_WIDTH - ACC_R2K);
                4096: in <= in_data << (ACC_WIDTH - ACC_R4K);
             default: in <= in_data;
            endcase
        end
    endgenerate
    
    generate
        if (DECIMATION == -8192)
        begin
        
        always @(posedge clock)
            case (decim)
                   1: in <= in_data;
                   2: in <= in_data << (ACC_WIDTH - ACC_R2);
                   4: in <= in_data << (ACC_WIDTH - ACC_R4);
                   8: in <= in_data << (ACC_WIDTH - ACC_R8);
                  16: in <= in_data << (ACC_WIDTH - ACC_R16);
                  32: in <= in_data << (ACC_WIDTH - ACC_R32);
                  64: in <= in_data << (ACC_WIDTH - ACC_R64);
                 128: in <= in_data << (ACC_WIDTH - ACC_R128);
                 256: in <= in_data << (ACC_WIDTH - ACC_R256);
                 512: in <= in_data << (ACC_WIDTH - ACC_R512);
                1024: in <= in_data << (ACC_WIDTH - ACC_R1K);
                2048: in <= in_data << (ACC_WIDTH - ACC_R2K);
                4096: in <= in_data << (ACC_WIDTH - ACC_R4K);
                8192: in <= in_data << (ACC_WIDTH - ACC_R8K);
             default: in <= in_data;
            endcase
        end
    endgenerate
    
    generate
        if (DECIMATION == -16384)
        begin
        
        always @(posedge clock)
            case (decim)
                   1: in <= in_data;
                   2: in <= in_data << (ACC_WIDTH - ACC_R2);
                   4: in <= in_data << (ACC_WIDTH - ACC_R4);
                   8: in <= in_data << (ACC_WIDTH - ACC_R8);
                  16: in <= in_data << (ACC_WIDTH - ACC_R16);
                  32: in <= in_data << (ACC_WIDTH - ACC_R32);
                  64: in <= in_data << (ACC_WIDTH - ACC_R64);
                 128: in <= in_data << (ACC_WIDTH - ACC_R128);
                 256: in <= in_data << (ACC_WIDTH - ACC_R256);
                 512: in <= in_data << (ACC_WIDTH - ACC_R512);
                1024: in <= in_data << (ACC_WIDTH - ACC_R1K);
                2048: in <= in_data << (ACC_WIDTH - ACC_R2K);
                4096: in <= in_data << (ACC_WIDTH - ACC_R4K);
                8192: in <= in_data << (ACC_WIDTH - ACC_R8K);
               16384: in <= in_data << (ACC_WIDTH - ACC_R16K);
             default: in <= in_data;
            endcase
        end
    endgenerate
    
    // for fixed decimation case only need to sign-extend IN_WIDTH input to fill ACC_WIDTH of first integrator
    generate
        if (DECIMATION > 0)
        begin
    
        always @(posedge clock)
            in <= in_data;	// will sign-extend since both declared signed
        end
    endgenerate
    
    
    // for fixed and variable decimation cases the generated code takes "out" from top OUT_WIDTH bits of last comb stage
    
    generate
        if (DECIMATION < 0)
        begin
            always @(posedge clock)
                if (out_strobe)
                    if (decim == 1)
                        out_data <= in[IN_WIDTH-1 -:OUT_WIDTH];
                    else
                        out_data <= out;
        end
    endgenerate
    
    generate
        if (DECIMATION > 0)
        begin
            always @(posedge clock)
                if (out_strobe) out_data <= out;
        end
    endgenerate
	
endmodule