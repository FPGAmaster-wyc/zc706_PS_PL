////////////////////////////////////////////////////////////////////////////////
// File:	axi_lite_to_mm.v
// Author:	FPGA_master <1975670198@qq.com>
// Description:
//	Transmission between FPGA and PC.
//
////////////////////////////////////////////////////////////////////////////////

module regfile(
    input                   aclk    ,
    input                   aresetn ,
	
	input           [7:0]   wr_addr ,
	input           [31:0]  wr_dout ,            
	input           [3:0]   wr_be   ,
	input                   wr_en   ,
	input           [7:0]   rd_addr ,
	input                   rd_en   ,
	output  reg     [31:0]  rd_din  ,          

    output                   done                                                
);

// register file
reg [31:0] reg_ctrl;	
reg [31:0] reg_rd_frame_size;
reg [31:0] reg_rd_next_address;

// controls
assign done = reg_ctrl[0];

//read message
assign RD_FRAM_SIZE = reg_rd_frame_size;
assign RD_NEXT_ADDRESS = reg_rd_next_address;

// write machine
always @(posedge aclk, negedge aresetn)
begin
    if(!aresetn) begin
        reg_ctrl <= 'b0;
        reg_rd_frame_size <= 'b0;
		reg_rd_next_address <= 'b0;
    end
    else if(wr_en) begin
        case(wr_addr[7:2])
            // soft_reset
            0: begin
                if(wr_be[0]) reg_ctrl[7:0] <= wr_dout[7:0];
                if(wr_be[1]) reg_ctrl[15:8] <= wr_dout[15:8];
                if(wr_be[2]) reg_ctrl[23:16] <= wr_dout[23:16];
                if(wr_be[3]) reg_ctrl[31:24] <= wr_dout[31:24];
            end
            // rd_frame_size
            1:  begin  
                if(wr_be[0]) reg_rd_frame_size[7:0] <= wr_dout[7:0];
                if(wr_be[1]) reg_rd_frame_size[15:8] <= wr_dout[15:8];
                if(wr_be[2]) reg_rd_frame_size[23:16] <= wr_dout[23:16];
                if(wr_be[3]) reg_rd_frame_size[31:24] <= wr_dout[31:24];
            end
			// rd_next_address
            2:  begin  
                if(wr_be[0]) reg_rd_next_address[7:0] <= wr_dout[7:0];
                if(wr_be[1]) reg_rd_next_address[15:8] <= wr_dout[15:8];
                if(wr_be[2]) reg_rd_next_address[23:16] <= wr_dout[23:16];
                if(wr_be[3]) reg_rd_next_address[31:24] <= wr_dout[31:24];
            end
            
        endcase
    end
    else begin
        // self-clean registers
        reg_ctrl[0] <= 1'b0; // soft-reset
    end
end

// read machine
always @(*)
begin
    case(rd_addr[7:2])
        // soft_reset
        0: rd_din = {31'd0,done};          
		// rd_frame_size
		1: rd_din = reg_rd_frame_size;
		// rd_next_address
		2: rd_din = reg_rd_next_address;


        default: rd_din = 'bx;
    endcase
end

endmodule
