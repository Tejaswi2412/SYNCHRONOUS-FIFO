// It connects fifo_ctrl and fifo_mem.
// fifo_ctrl gives instructions to fifo_mem . full and empty are the ports of fifo_top and outside world needs to know that whether you can write or read.

`timescale 1ns/1ps
module fifo_top(input clk, input [7:0] data_in, input reset, wr_en ,rd_en, output [7:0] data_out, output full , empty );
      
      wire [2:0] wr_addr , rd_addr ;
      wire wr_en_mem , rd_en_mem;
      fifo_ctrl instant1(.clk(clk), .wr_en(wr_en), .rd_en(rd_en), .reset(reset), .wr_addr(wr_addr) ,.rd_addr(rd_addr) ,.full(full) , .empty(empty), .wr_en_mem(wr_en_mem),.rd_en_mem(rd_en_mem));
      fifo_mem instant2(.clk(clk), .data_in(data_in), .wr_en(wr_en_mem), .rd_en(rd_en_mem), .wr_addr(wr_addr) ,.rd_addr(rd_addr), .data_out(data_out));


endmodule