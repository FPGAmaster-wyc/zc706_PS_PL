module axi_hp_wr #
(
		parameter integer M_AXI_ADDR_WIDTH	= 32    ,
		parameter integer M_AXI_DATA_WIDTH	= 64    
	)


(
    input                   i_clk           ,
    input                   i_rst_n         ,

    // PS 写数据完成
    input                  i_wr_done       ,

    //写入数据
    input       [M_AXI_DATA_WIDTH-1:0]      S_WR_tdata          ,       
    input                   S_WR_tvalid         ,
    input                   S_WR_tlast          ,
    output reg              S_WR_tready    ,

  
    //读出数据
    output                  M_RD_tlast          ,
    output                  M_RD_tvalid         ,
    output  [M_AXI_DATA_WIDTH-1:0]          M_RD_tdata          ,
    input                   M_RD_tready    , 


     //debug信号
    output [2:0]  debug_c_state,
    output [2:0]  debug_n_state,

    output [2:0]  debug_rd_c_state,
    output [2:0]  debug_rd_n_state,


    //AXI总线    
    input   wire  m_axi_init_axi_txn,
    output  wire  m_axi_txn_done,
    output  wire  m_axi_error,
    input   wire  m_axi_aclk,
    input   wire  m_axi_aresetn,
    output  wire m_axi_awid,
    output  wire [M_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr,
    output  wire [7 : 0] m_axi_awlen,
    output  wire [2 : 0] m_axi_awsize,
    output  wire [1 : 0] m_axi_awburst,
    output  wire  m_axi_awlock,
    output  wire [3 : 0] m_axi_awcache,
    output  wire [2 : 0] m_axi_awprot,
    output  wire [3 : 0] m_axi_awqos,
    output  wire  m_axi_awuser,
    output  wire  m_axi_awvalid,
    input   wire  m_axi_awready,
    output  wire [M_AXI_DATA_WIDTH-1 : 0] m_axi_wdata,
    output  wire [M_AXI_DATA_WIDTH/8-1 : 0] m_axi_wstrb,
    output  wire  m_axi_wlast,
    output  wire  m_axi_wuser,
    output  wire  m_axi_wvalid,
    input   wire  m_axi_wready,
    input   wire m_axi_bid,
    input   wire [1 : 0] m_axi_bresp,
    input   wire  m_axi_buser,
    input   wire  m_axi_bvalid,
    output  wire  m_axi_bready,
    output  wire  m_axi_arid,
    output  wire [M_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr,
    output  wire [7 : 0] m_axi_arlen,
    output  wire [2 : 0] m_axi_arsize,
    output  wire [1 : 0] m_axi_arburst,
    output  wire  m_axi_arlock,
    output  wire [3 : 0] m_axi_arcache,
    output  wire [2 : 0] m_axi_arprot,
    output  wire [3 : 0] m_axi_arqos,
    output  wire  m_axi_aruser,
    output  wire  m_axi_arvalid,
    input   wire  m_axi_arready,
    input   wire  m_axi_rid,
    input   wire [M_AXI_DATA_WIDTH-1 : 0] m_axi_rdata,
    input   wire [1 : 0] m_axi_rresp,
    input   wire  m_axi_rlast,
    input   wire  m_axi_ruser,
    input   wire  m_axi_rvalid,
    output  wire  m_axi_rready
    
);

    //写数据    
    reg     [M_AXI_DATA_WIDTH-1:0]  w_data      ;
    reg             w_valid     ;
    wire            w_ready     ;
    reg             w_last      ;
    reg     [3:0]   w_strb      ;           //写字节选通信号    64位：1111_1111 (一个字节一位，64bit位8字节，所以是八位)

    //写地址    
    reg     [M_AXI_ADDR_WIDTH-1:0]  aw_addr     ;
    reg     [7:0]   aw_len      ;           //突发长度类型：两个last信号的间隔（单位为：时钟周期） （取决于你的数据大小（本次为例：binning数据为233个时钟传完，所以突发长度为>233，）
    reg     [2:0]   aw_size     ;           //传输中的字节数 011 ：8B
    reg     [1:0]   aw_burst    ;           //突发类型      01 ：递增突发
    reg             aw_valid    ;
    wire            aw_ready    ;
    
    //写响应        
    wire    [1:0]   b_resp      ;
    wire            b_valid     ;
    reg             b_ready     ;

    reg     [11:0]  number_cnt  ;       //一次突发传输的数据计数
    reg     [31:0]  aw_addr_cnt ; 
    reg     [11:0]  burst_count ;

    reg     [2:0]   c_state     ;
    reg     [2:0]   n_state     ;
    localparam  IDLE        =   3'd0,
                FRAME       =   3'd1,
                FRAME_LOOP  =   3'd2,
                WR_ADDR     =   3'd3,
                WR_DATA     =   3'd4,
                LAST_DATA   =   3'd5,
                STOP        =   3'd6;

    //大端转小端 输入数据处理
    wire [63:0] i_data;   
    wire        i_valid;
    wire        o_ready;
    wire        i_last;
    
    assign i_data = S_WR_tdata;
    assign i_valid = S_WR_tvalid;
    assign i_last = S_WR_tlast;
            
    //状态转换 FSM31
    always @ (posedge i_clk, negedge i_rst_n) begin  :   W_FMS1
        if (~i_rst_n)
            c_state <= 0;
        else
            c_state <= n_state;
    end
   
    //状态跳转条件 FSM32
    always @ (*) begin  :   W_FMS2
            case (c_state)                                  
                IDLE  :   begin
                            if (i_valid)
                                n_state = WR_ADDR;
                            else
                                n_state = IDLE;
                end

                WR_ADDR :   begin
                                if (aw_ready)
                                    n_state = WR_DATA;
                                else    
                                    n_state = WR_ADDR;
                end

                WR_DATA :   begin 
                                if (number_cnt == aw_len - 1 && w_ready)
                                    n_state = LAST_DATA;
                                else
                                    n_state = WR_DATA;
                end

                LAST_DATA    :   begin
                                    if (w_ready)
                                        n_state = STOP;
                                    else
                                        n_state = LAST_DATA;
                end

                STOP    :   begin
                                n_state = IDLE;
                end

                default :  n_state = 'bx ;

            endcase
    end

    //状态执行的操作 FSM33
    always @ (posedge i_clk, negedge i_rst_n) begin  :   W_FMS3
        if (~i_rst_n)
            begin   
                w_data          <= 0;
                w_valid         <= 0;
                w_last          <= 0;
                w_strb          <= 0;

                aw_addr         <= 0;
                aw_len          <= 0;
                aw_size         <= 0;
                aw_burst        <= 0;
                aw_valid        <= 0;   

                aw_addr_cnt     <= 32'h10000000;                         
             
            end
        else
            case (n_state)
                                
                IDLE    :   begin
                        end
                        
                WR_ADDR :   begin                                               //写地址和aw信息
                                w_strb          <= 4'b1111 ;
                                aw_size         <= 3'b010       ;
                                aw_burst        <= 2'b01        ;
                                aw_valid        <= 1            ;
                                aw_addr         <= aw_addr_cnt  ;
                                aw_len          <= 8'd3; 
                end

                WR_DATA :   begin
                                aw_valid <= 0;
                                if (w_ready && i_valid)
                                    begin
                                        w_valid     <= 1;
                                        w_data      <= i_data;
                                    end 
                                else
                                    begin
                                        w_data      <= w_data       ;
                                    end
                end

                LAST_DATA    :   begin
                                    w_last      <= 1            ;  
                                    if (w_ready && i_valid)
                                    begin
                                        w_valid     <= 1;
                                        w_data      <= i_data;
                                    end 
                                else
                                    begin
                                        w_data      <= w_data       ;
                                    end                               //最后一个数据             
                end

                STOP    :   begin                               
                                w_last  <= 0        ;
                                w_valid <= 0        ;
                end

                default :   ;
            endcase
    end   
    
    //突发数据计数
    always @(posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            number_cnt <= 0;
        else if (w_last)
            number_cnt <= 0;
        else if (w_ready && w_valid)
            number_cnt <= number_cnt + 1;
        else 
        number_cnt <=number_cnt;
    end 

    //fifo ready信号处理
    always @(*) begin
        case (n_state) /* full_case */
            WR_DATA :   begin
                            S_WR_tready = w_ready; 
            end

            LAST_DATA   :   begin
                                S_WR_tready = w_ready; 
            end 

            STOP    :   begin
                                S_WR_tready = 0;  
            end

            default: begin
                        S_WR_tready = 0;
            end

        endcase
    end

    //写响应处理
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            b_ready <= 0;
        else
            b_ready <= 1;
    end

    //debug
    assign debug_c_state = c_state;
    assign debug_n_state = n_state;


    //读地址和数据



    reg     [31:0]      ar_addr     ;
    reg     [7:0]       ar_len      ;
    reg     [2:0]       ar_size     ;
    reg     [1:0]       ar_burst    ;
    reg                 ar_valid    ; 
    wire                ar_ready    ; 

    wire    [M_AXI_DATA_WIDTH-1:0]      r_data      ; 
    wire                r_resp      ;
    wire                r_last      ;
    wire                r_valid     ;
    wire                r_ready     ;

    reg     [2:0]       rd_state_c  ; 
    reg     [2:0]       rd_state_n  ;
    reg     [31:0]      rd_addr_buff;
    wire     [M_AXI_DATA_WIDTH-1:0]      rd_data_buff;

    reg     [31:0]  r_CMD_TX_LINE_B;    //存储PC发的指令大小

    reg     [31:0]      num_rd_cnt  ;

    localparam  WAIT_RD   = 0,            //状态
                RD_ADDR     = 1,
                RD_FIFO     = 2,
                RD_DATA     = 3,
                RD_LAST     = 4,
                RD_STOP     = 5;

 
    always @ (posedge i_clk, negedge i_rst_n) begin  :   R_FMS1
        if (~i_rst_n)
            rd_state_c <= WAIT_RD;
        else
            rd_state_c <= rd_state_n;
    end

    always @ (*) begin  :   R_FMS2
        case (rd_state_c)
            WAIT_RD   :   begin
                                if (i_wr_done == 1/*i_wr_done == 1*/)     //检测到写完成
                                    rd_state_n = RD_ADDR;
                                else
                                    rd_state_n = WAIT_RD;
            end

            RD_ADDR :   begin
                            if (ar_ready)
                                rd_state_n = RD_DATA;
                            else
                                rd_state_n = RD_ADDR;
            end

            RD_DATA :   begin
                            if (num_rd_cnt == ar_len - 1)
                                rd_state_n = RD_LAST;
                            else
                                rd_state_n = RD_DATA;

            end

            RD_LAST :   begin
                                rd_state_n = RD_STOP;
                            
            end 

            RD_STOP :   begin
                            rd_state_n = WAIT_RD;
            end

            default :   begin
                            rd_state_n = 0; 
            end

        endcase 
    end

    always @ (posedge i_clk, negedge i_rst_n) begin  :   R_FMS3
        if (~i_rst_n)
            begin
                ar_addr         <= 0;
                ar_len          <= 0;
                ar_burst        <= 0;
                ar_size         <= 0;
                ar_valid        <= 0;

                r_CMD_TX_LINE_B <= 0;

                rd_addr_buff    <= 32'h2000_0000;
            end
        else
            case (rd_state_n)
                WAIT_RD   :   begin
                                    ar_valid        <= 0        ;                                
                end

                RD_ADDR :   begin                               //读地址和ar信息
                            
                                ar_valid    <= 1            ;
                                ar_addr     <= rd_addr_buff ;
                                ar_len      <= 8'd3            ;
                                ar_burst    <= 2'b01        ;
                                ar_size     <= 3'b010       ;  
                end

                RD_DATA :   begin
                                ar_valid <= 0   ; 
                end
            endcase 
    end
 
    //r_ready 处理
    assign r_ready = M_RD_tready;
    assign rd_data_buff = r_data;
    assign M_RD_tvalid = r_valid;
    assign M_RD_tlast = r_last;

    //读突发数据计数
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            num_rd_cnt <= 0;
        else if (r_last)
            num_rd_cnt <= 0;
        else if (r_valid && M_RD_tready)
            num_rd_cnt <= num_rd_cnt + 1;
        else
            num_rd_cnt <= num_rd_cnt;
    end




    //读数据 小端数据转大端

    assign M_RD_tdata = {   rd_data_buff[7:0]   ,
                        rd_data_buff[15:8]  ,
                        rd_data_buff[23:16] ,
                        rd_data_buff[31:24] 
                    };

    //assign M_RD_tdata = rd_data_buff;
  

    assign debug_rd_c_state = rd_state_c;
    assign debug_rd_n_state = rd_state_n;

      

    assign m_axi_wdata      = w_data        ;
	assign m_axi_wvalid     = w_valid       ;
	assign m_axi_wlast      = w_last        ;
	assign m_axi_wstrb      = w_strb        ;
	assign w_ready          = m_axi_wready  ;

	assign m_axi_awaddr     = aw_addr       ;
	assign m_axi_awlen      = aw_len        ;
	assign m_axi_awsize     = aw_size       ;
	assign m_axi_awburst    = aw_burst      ;
	assign m_axi_awvalid    = aw_valid      ;
	assign aw_ready         = m_axi_awready ;

	assign b_resp           = m_axi_bresp   ;
	assign b_valid          = m_axi_bvalid  ;
	assign m_axi_bready     = b_ready       ;

    assign m_axi_araddr     = ar_addr       ;
    assign m_axi_arlen      = ar_len        ;
    assign m_axi_arsize     = ar_size       ;
    assign m_axi_arburst    = ar_burst      ;
    assign m_axi_arvalid    = ar_valid      ;
    assign ar_ready         = m_axi_arready ;
    
    assign r_data           = m_axi_rdata   ;
    assign r_last           = m_axi_rlast   ;
    assign r_resp           = m_axi_rresp   ;
    assign r_valid          = m_axi_rvalid  ;
    assign m_axi_rready     = r_ready       ;
  
    assign m_axi_txn_done   = 0;
	assign m_axi_error      = 0;
	assign m_axi_awid       = 0;
	assign m_axi_awlock     = 0;
	assign m_axi_awcache    = 3;
	assign m_axi_awprot     = 0;
	assign m_axi_awqos      = 0;
	assign m_axi_awuser     = 0; 
	assign m_axi_wuser      = 0;
	assign m_axi_arid       = 0;
	assign m_axi_arlock     = 0;
	assign m_axi_arcache    = 3;
	assign m_axi_arprot     = 0;
	assign m_axi_arqos      = 0;
	assign m_axi_aruser     = 0;

endmodule