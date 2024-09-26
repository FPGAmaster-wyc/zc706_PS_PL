module rx_lvds(
    input                       clk,
    input                       rst_n,
    
    input                       lvds_data0,
    input                       lvds_data1,
    input                       lvds_flag,
    input                       user_irq_ack,
    
    input                       wr_rst_busy,    

    input                       s_axis_tready,      
    output                      s_axis_tvalid,
    output  reg                 s_axis_tlast,
    output           [7:0]      s_axis_tdata,

    output                      lvds_clk,
    output  reg                 lvds_busy,
    output  reg     [31:0]      frame1,
    output  reg                 usr_irq_req 
    );
    
    parameter           s0 = 2'b00;             //�ȴ����ݽ���
    parameter           s1 = 2'b01;             //���ݽ���
    parameter           s2 = 2'b10;             //֡�������
    parameter           s3 = 2'b11;             //�жϴ���
    
    parameter           ONE_FRAME = 14'd3584;
//    parameter           ONE_FRAME = 14'd3585;             //һ֡����   896��Ч����

    reg            [16:0]      one_frame_cnt;              //ʱ�Ӽ���
    reg            [31:0]       frame;                       //֡����
    reg            [1:0]       state, state_next;  
    reg            [31:0]       frame_cnt;                   //�ȴ��жϴ�������
    reg                        frame_flag;
    
    /*
        IBUFGDS clk_diff (
        .O (clk), 
        .I (clk_p), 
        .IB (clk_n)
    );
    
    IBUFDS data0_diff (
        .O (lvds_data0), 
        .I (lvds_data0_p), 
        .IB (lvds_data0_n)
    );
    
    IBUFDS data1_diff (
        .O (lvds_data1), 
        .I (lvds_data1_p), 
        .IB (lvds_data1_n)
    );
    
    IBUFDS flag_diff (
        .O (lvds_flag), 
        .I (lvds_flag_p), 
        .IB (lvds_flag_n)
    );   
    */
    
    
    
    //�жϴ���״̬�ȴ�����
    always @ (posedge clk, negedge rst_n)               
    begin
        if (!rst_n)
            frame_flag <= 0;
        else if (frame_cnt == 32'd10000)        //10��δ�������ݣ��ж�ʹ��
            frame_flag <= 1;
        else 
            frame_flag <= 0;          
    end 
    //һ��
    always @ (posedge clk, negedge rst_n)
    begin
        if (!rst_n)
            state <= s0;
        else 
            state <= state_next; 
    end
    //����״̬��ת
    always @(*)
    begin
        case (state)
            s0  :   begin                   //�ȴ�������Ч�ź�
                        state_next = s1;
                    end
            s1  :   begin                   //������Ч����
                    if (lvds_flag)
                        state_next = s1;
                    else 
                        state_next = s3;
                    end
            s3  :   begin                   //�����ж�
                    if (frame_flag)
                        state_next <= s0;
                    else if (lvds_flag)
                        state_next = s1;
                    else 
                        state_next <= s3;
                    end 
            default :   begin
                        state_next = 'bx;
                        end
        endcase
    end 
    reg         [3:0]       data0;              //data0����ƴ�ӼĴ�
    reg         [3:0]       data1;              //data1����ƴ�ӼĴ�
    wire         [7:0]       data;               //�������
    reg         [3:0]       cnt;                //������Ч����ʹ�ܼ���
    reg                     cnt_en;             //��Ч����ʹ�ܼĴ�   

    always @ (posedge clk , negedge rst_n)
    begin 
        if (!rst_n)
        begin
            data0 <= 0;
            data1 <= 0;
            lvds_busy <= 0;
            frame_cnt <= 0;
        end 
        else case (state_next)
            s0  :   begin
                        lvds_busy <= 1; 
                        frame_cnt <= 0;
                    end 
            s1  :   begin  
                    if (one_frame_cnt > ONE_FRAME - 1) 
                        begin
                            data0 <= {lvds_data0,data0[3:1]};
                            data1 <= {lvds_data1,data1[3:1]};
                        end 
                    else
                        begin
                            data0 <= {lvds_data0,data0[3:1]};
                            data1 <= {lvds_data1,data1[3:1]};
                        end               
                    end 
            s3  :   begin
                        if (frame_cnt < 8'd10)
                            frame_cnt <= frame_cnt + 1;
                        else 
                            frame_cnt <= 0;
                    end 
        endcase
    end
    assign data = cnt_en ? {data1,data0} : data;
    
    parameter               frame_cnt_s1 = 2'b00, frame_cnt_s2 = 2'b01; 
    reg             [1:0]   frame_cnt1;
    
    always @ (posedge clk, negedge rst_n)
    begin
        if (!rst_n)
            begin
                one_frame_cnt <= 0;
                frame_cnt1 <= frame_cnt_s1;
            end 
        else if (state_next == s1)
        case (frame_cnt1)
            frame_cnt_s1    :   if (one_frame_cnt == 0)
                                    frame_cnt1 <= frame_cnt_s2;
                                else 
                                    one_frame_cnt <= 0;
            frame_cnt_s2    :   begin
                                    if (!lvds_flag)
                                        frame_cnt1 <= frame_cnt_s1;
                                    else if (one_frame_cnt < ONE_FRAME - 1)
                                        one_frame_cnt <= one_frame_cnt + 1;
                                    else if (one_frame_cnt == ONE_FRAME - 1)
                                        one_frame_cnt <= 0;
                                    else 
                                        frame_cnt1 <= frame_cnt_s2;
                                end 
        endcase 
        else 
            one_frame_cnt <= 0;
    end 
    
    //����������
    
    always @ (posedge clk, negedge rst_n)
    begin
        if (!rst_n)
            frame <= 0;
        else if (one_frame_cnt == ONE_FRAME - 1)     //����һ֡���ݼ�һ
            frame <= frame + 1;
        else if (frame == 32'd1000 | frame_flag)
            frame <= 0;    
        else 
            frame <= frame;
    end    
    
        always @ (posedge clk, negedge rst_n)
    begin
        if (!rst_n)
            frame1 <= 0;
        else if (frame1 == 32'd10000)
            frame1 <= 0; 
        else if (one_frame_cnt == ONE_FRAME - 1)     //����һ֡���ݼ�һ
            frame1 <= frame1 + 1;   
        else 
            frame1 <= frame1;
    end
    //�ж��ź�
    always @ (posedge clk, negedge rst_n)
    begin
        if (!rst_n)
            usr_irq_req <= 0;
        else if (frame == 32'd1000 | frame_flag)        //frame���������ж� �� 10��δ�������ݴ����ж�
                usr_irq_req <= 1;
        else if (user_irq_ack)                          //�жϴ������ܳɹ�
            usr_irq_req <= 0;
        else 
            usr_irq_req <= usr_irq_req;
    end 
    //����last�ź�
    
    always @ (posedge clk, negedge rst_n)
    begin
        if (!rst_n)
            s_axis_tlast <= 0;
        else if (one_frame_cnt == ONE_FRAME - 1)         //һ֡���ݷ��ͽ���
            s_axis_tlast <= 1;
        else    
            s_axis_tlast <= 0; 
    end
    //������Ч����ʹ���ź�
    reg           [1:0]   cnt_1;
    parameter               cnt_s1= 0, cnt_s2 = 1; 
    always @ (posedge clk , negedge rst_n)
    begin
        if (!rst_n)
            begin
                cnt <= 0;
                cnt_1 <= cnt_s1;
            end 
        else if (state_next == s1 )
            case (cnt_1)
                cnt_s1  :  if (cnt == 0)
                             cnt_1 <= cnt_s2;
                           else 
                             cnt <= 0;
                 cnt_s2 :   begin
                                if (!lvds_flag)
                                    cnt_1 <= cnt_s1;
                                else if (cnt < 3'd4 - 1)
                                    cnt <= cnt + 1;
                                else if (cnt == 3'd4 - 1)
                                    cnt <= 0;
                                else
                                    cnt_1<= cnt_s2;
                            end 
            endcase
        else 
            cnt <= 0;
    end 
    always @ (posedge clk , negedge rst_n)
    begin
        if (!rst_n)
            cnt_en <= 0;
        else if (cnt == 3'd4 - 1)
            cnt_en <= 1;
        else 
            cnt_en <= 0;
    end 
    
    assign s_axis_tvalid = cnt_en ? 1'b1 : 1'b0;           
    assign s_axis_tdata = s_axis_tvalid ? data : 1'b0;
    
    assign lvds_clk =clk;
        
endmodule
