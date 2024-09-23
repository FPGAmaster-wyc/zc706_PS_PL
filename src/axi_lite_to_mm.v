////////////////////////////////////////////////////////////////////////////////
// File:	axi_lite_to_mm.v
// Author:	FPGA_master <1975670198@qq.com>
// Description:
//	AXI lite interface to MM interface.
//
////////////////////////////////////////////////////////////////////////////////

module axi_lite_to_mm #(
	parameter ADDR_BITS=32,
	parameter DATA_BITS=32,
	parameter DATA_BYTES=DATA_BITS/8
)(
	input	s_axi_aclk,
	input	s_axi_aresetn,

	input	[ADDR_BITS-1:0] s_axi_awaddr,
	input	s_axi_awvalid,
	output	s_axi_awready,

	input	[DATA_BITS-1:0] s_axi_wdata,
	input	[DATA_BYTES-1:0] s_axi_wstrb,
	input	s_axi_wvalid,
	output	s_axi_wready,

	output	[1:0] s_axi_bresp,
	output	s_axi_bvalid,
	input	s_axi_bready,

	input	[ADDR_BITS-1:0] s_axi_araddr,
	input	s_axi_arvalid,
	output	s_axi_arready,

	output	[DATA_BITS-1:0] s_axi_rdata,
	output	[1:0] s_axi_rresp,
	output	s_axi_rvalid,
	input	s_axi_rready,

	output	[ADDR_BITS-1:0] wr_addr,
	output	[DATA_BITS-1:0] wr_dout,
	output	[DATA_BYTES-1:0] wr_be,
	output	wr_en,
	input	wr_ready,

	output	[ADDR_BITS-1:0] rd_addr,
	input	[DATA_BITS-1:0] rd_din,
	output	rd_en,
	input	rd_ready
);


reg awready_r;
reg wready_r;
reg [1:0] bresp_r;
reg bvalid_r;
reg arready_r;
reg [31:0] rdata_r;
reg rvalid_r;
reg [1:0] rresp_r;

reg [ADDR_BITS-1:0] write_addr;
reg [31:0] write_data;
reg write_enable;
reg [3:0] write_be;
wire write_done;

reg [ADDR_BITS-1:0] read_addr;
wire [31:0] read_data;
reg read_enable;
wire read_done;

assign s_axi_awready = awready_r;
assign s_axi_wready = wready_r;
assign s_axi_bresp = bresp_r;
assign s_axi_bvalid = bvalid_r;
assign s_axi_arready = arready_r;
assign s_axi_rdata = rdata_r;
assign s_axi_rresp = rresp_r;
assign s_axi_rvalid = rvalid_r;

assign wr_addr = write_addr;
assign wr_dout = write_data;
assign wr_be = write_be;
assign wr_en = write_enable;
assign write_done = write_enable && wr_ready;

assign rd_addr = read_addr;
assign rd_en = read_enable;
assign read_data = rd_din;
assign read_done = read_enable && rd_ready;

////////////////////////////////////////////////////////////////////////////////
// AXI stage
//% Write Stage
//% Address acknowledge
always @(posedge s_axi_aclk,negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		awready_r <= 1'b1;
	end
	else if(awready_r) begin
		if(s_axi_awvalid) begin
			awready_r <= 1'b0;
		end
	end
	else if(s_axi_bvalid && s_axi_bready) begin
		awready_r <= 1'b1;
	end
end

//% Data acknowledge
always @(posedge s_axi_aclk,negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		wready_r <= 1'b1;
	end
	else if(wready_r) begin
		if(s_axi_wvalid) begin
			wready_r <= 1'b0;
		end
	end
	else if(s_axi_bvalid && s_axi_bready) begin
		wready_r <= 1'b1;
	end
end

//% Write response
always @(posedge s_axi_aclk,negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		bvalid_r <= 1'b0;
		bresp_r <= 2'b0;
	end
	else if(s_axi_bvalid && s_axi_bready) begin
		bvalid_r <= 1'b0;
	end
	else if(write_done) begin
		bvalid_r <= 1'b1;
	end
end

//% Data write 
always @(posedge s_axi_aclk)
begin
	if(s_axi_awvalid && s_axi_awready) begin
		write_addr <= s_axi_awaddr;
	end
	if(s_axi_wvalid && s_axi_wready) begin
		write_data <= s_axi_wdata;
		write_be <= s_axi_wstrb;
	end
end

//% Write strobe
always @(posedge s_axi_aclk, negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		write_enable <= 1'b0;
	end
	else if((s_axi_awvalid&&s_axi_awready&&s_axi_wvalid&&s_axi_wready) 
		|| (!s_axi_awready&&s_axi_wvalid&&s_axi_wready)
		|| (!s_axi_wready&&s_axi_awvalid&&s_axi_awready)) begin
		write_enable <= 1'b1;
	end
	else if(write_done) begin
		write_enable <= 1'b0;
	end
end

//% Read Stage
//% Read Address Acknowledge
always @(posedge s_axi_aclk, negedge s_axi_aresetn)
begin
	if(!s_axi_aresetn) begin
		arready_r <= 1'b1;
	end
	else if(s_axi_arvalid && arready_r) begin
		arready_r <= 1'b0;
	end
	else if(s_axi_rvalid && s_axi_rready) begin
		arready_r <= 1'b1;
	end
end

//% Read Data Response
always @(posedge s_axi_aclk, negedge s_axi_aresetn) 
begin
	if(!s_axi_aresetn) begin
		rvalid_r <= 1'b0;
		rresp_r <= 2'b0;
		rdata_r <= 'bx;
	end
	else if(read_done) begin
		rdata_r <= read_data;
		rvalid_r <= 1'b1;
	end
	else if(s_axi_rvalid && s_axi_rready) begin
		rvalid_r <= 1'b0;
	end
end

//% Read strobe
always @(posedge s_axi_aclk, negedge s_axi_aresetn) 
begin
	if(!s_axi_aresetn) begin
		read_enable <= 1'b0;
		read_addr <= 'bx;
	end
	else if(arready_r && s_axi_arvalid) begin
		read_addr <= s_axi_araddr;
		read_enable <= 1'b1;
	end
	else if(read_done) begin
		read_enable <= 1'b0;
	end
end


endmodule
