// generated file

// CIC: INTEG_COMB|MODE_REAL N=5 R=1024 M=1 Bin=24 Bout=16
// growth 50 = ceil(N=5 * log2(R=1024)=10)
// Bin 24 + growth 50 = acc_max 74 

wire signed [73:0] integrator0_data;
wire signed [73:0] integrator1_data;
wire signed [73:0] integrator2_data;
wire signed [73:0] integrator3_data;
wire signed [73:0] integrator4_data;
wire signed [25:0] integrator5_data;
wire signed [25:0] comb0_data;
wire signed [21:0] comb1_data;
wire signed [20:0] comb2_data;
wire signed [19:0] comb3_data;
wire signed [18:0] comb4_data;
wire signed [18:0] comb5_data;

// important that "in" be declared signed by wrapper code
// so this assignment will sign-extend:
assign integrator0_data = in;

cic_integrator #(.WIDTH(74)) cic_integrator1_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator0_data[73 -:74]),	// trunc 0 bits (should always be zero)
	.out_data(integrator1_data)
);

cic_integrator #(.WIDTH(74)) cic_integrator2_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator1_data[73 -:74]),	// trunc 0 bits 
	.out_data(integrator2_data)
);

cic_integrator #(.WIDTH(74)) cic_integrator3_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator2_data[73 -:74]),	// trunc 0 bits 
	.out_data(integrator3_data)
);

cic_integrator #(.WIDTH(74)) cic_integrator4_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator3_data[73 -:74]),	// trunc 0 bits 
	.out_data(integrator4_data)
);

cic_integrator #(.WIDTH(26)) cic_integrator5_inst(
	.clock(clock),
	.reset(reset),
	.strobe(in_strobe),
	.in_data(integrator4_data[73 -:26]),	// trunc 48 bits 
	.out_data(integrator5_data)
);

assign comb0_data = integrator5_data;

cic_comb #(.WIDTH(22)) cic_comb1_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb0_data[25 -:22]),	// trunc 4 bits 
	.out_data(comb1_data)
);

cic_comb #(.WIDTH(21)) cic_comb2_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb1_data[21 -:21]),	// trunc 1 bits 
	.out_data(comb2_data)
);

cic_comb #(.WIDTH(20)) cic_comb3_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb2_data[20 -:20]),	// trunc 1 bits 
	.out_data(comb3_data)
);

cic_comb #(.WIDTH(19)) cic_comb4_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb3_data[19 -:19]),	// trunc 1 bits 
	.out_data(comb4_data)
);

cic_comb #(.WIDTH(19)) cic_comb5_inst(
	.clock(clock),
	.reset(reset),
	.strobe(out_strobe),
	.in_data(comb4_data[18 -:19]),	// trunc 0 bits 
	.out_data(comb5_data)
);

assign out = comb5_data[18 -:16] + comb5_data[2];	// trunc 3 bits, rounding applied
