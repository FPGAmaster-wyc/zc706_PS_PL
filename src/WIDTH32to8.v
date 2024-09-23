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


module WIDTH32to8(
    input clk,
    input rst_n,

    input [31:0] data_in,
    input data_en,
    output reg ready,

    
    output reg data_valid,
    output reg [7:0] data_out
    );

    reg en_flag; 
    reg tran_down;
    reg [31:0] data_in_temp;


    reg [3:0] data_cnt;



    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_flag <= 0;
            data_in_temp <= 0;
            ready <= 1;
        end
        else if (ready)
            ready <= 0;
        else if (data_en && !en_flag) begin
            en_flag <= 1;
            ready <= 1;
            data_in_temp <= data_in;
        end 
        else if (data_cnt == 3)
            en_flag <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_cnt <= 4;
        end
        else if (data_en && !en_flag) begin
            data_cnt <= 0;
        end 
        else if (en_flag) begin
            data_cnt <= data_cnt + 1;
        end 
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            data_valid <= 0;
        end 
        else 
            case (data_cnt)
                0   :   begin
                    data_out <= data_in_temp[7:0];
                    data_valid <= 1;
                end
                1   : begin
                    data_out <= data_in_temp[15:8];
                    data_valid <= 1;
                end
                2   : begin
                    data_out <= data_in_temp[23:16];
                    data_valid <= 1;
                end 
                3   : begin

                    data_out <= data_in_temp[31:24];
                    data_valid <= 1;
                end

                default:data_valid <= 0;

            endcase
    end

endmodule
