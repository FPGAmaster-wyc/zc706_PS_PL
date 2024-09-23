`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/18 15:31:39
// Design Name: 
// Module Name: WIDTH8to32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module WIDTH8to32(
    input clk,
    input rst_n,

    input [7:0] data_in,
    input data_en,

    output reg data_last,
    output reg data_valid,
    output reg [31:0] data_out
    );


    reg [31:0] data_out_temp;
    reg [1:0] data_cnt;
    reg [15:0] data_num;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_temp <= 0;
            data_cnt <= 0;
            data_num <= 0;
        end
        else if (data_en)
            begin
                data_cnt <= data_cnt + 1;
                data_out_temp <= {data_out_temp[24:0], data_in};
                data_num <= data_num + 1;
            end
        else if (data_last) begin
            data_num <= 0;
        end 
    end 

    reg data_en_r;

    always @(posedge clk) begin
        data_en_r <= data_en;
    end 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            data_valid <= 0;
        end
        else if (data_en_r && data_cnt == 0 && data_num != 0) begin
            data_out <= data_out_temp;
            data_valid <= 1;
        end
        else
            data_valid <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_last <= 0;
        else if (data_en_r && data_cnt == 0 && data_num != 0 && data_num == 16) 
            data_last <= 1;
        else
            data_last <= 0;
    end


endmodule
