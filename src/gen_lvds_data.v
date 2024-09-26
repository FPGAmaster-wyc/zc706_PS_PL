module gen_lvds_data(

    input   clk,
    input   rst_n,
    
    
    input sw_flag,
    output reg data0,
    output reg data1,
    output reg flag

    );

    reg [7:0] idx;
    reg [15:0] type_cnt;
    reg [15:0] frame_cnt;
    reg [7:0] data;


    //位计数
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n)
            idx <= 8'd7;
        else if (idx == 3)
            idx <= 3'b0;
        else
            idx <= idx + 1;
    end 

    //字节计数 每896字节是一帧
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n)
            type_cnt <= 16'd0;
        else if (idx == 2'b11)
            if (type_cnt == 895)
                type_cnt <= 16'd0;
            else
                type_cnt <= type_cnt + 1;
    end 

    //帧计数 发送10帧数据
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n)
            frame_cnt <= 16'd0;
        else if (type_cnt == 895 && idx == 8'd3)
            if (frame_cnt == 9)
                frame_cnt <= 16'd0;
            else
                frame_cnt <= frame_cnt + 1;
    end

    //数据
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) 
            data <= 8'd0;
        else if (idx == 2'b11)
            data <= data + 1;
    end

    //数据输出
    always @(*) begin
        case (idx)
            0   :   begin
                        data0 = data[0];
                        data1 = data[4];
                        flag = 1'b1;
            end  

            1   :   begin
                        data0 = data[1];
                        data1 = data[5];
                        flag = 1'b1;
            end  

            2   :   begin
                        data0 = data[2];
                        data1 = data[6];
                        flag = 1'b1;
            end  

            3   :   begin
                        data0 = data[3];
                        data1 = data[7];
                        flag = 1'b1;
            end  

            default: begin
                        data0 = 1'b0;
                        data1 = 1'b0;
                        flag = 1'b0;
            end

        endcase 
    end

endmodule
