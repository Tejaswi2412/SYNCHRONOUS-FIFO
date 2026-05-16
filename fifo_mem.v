// FIFO (FIRST IN FIRST OUT)
// It is a register having 8 slots and each slot is of 1 byte . means fifo is of 8 bytes
// It is a queue . The data is present in the queue and data does not get lost.

// fifo_mem answers where to store data? , when to store data? , what to store ?

`timescale 1ns/1ps
module fifo_mem( input clk, wr_en , rd_en ,input [2:0] wr_addr, rd_addr , input [7:0] data_in , output reg [7:0] data_out);

reg [7:0] mem [0:7];
 always@(posedge clk)begin
    if(wr_en) begin

        mem[wr_addr]<= data_in;
    end

 // if i put  else mem[wr_addr]=0 , this would mean that i am erasing the data when wr_en is low . Hence it is not needed
        
    if(rd_en)
        data_out <= mem[rd_addr];

// if i write else statement for read then when rd_en is low , the data_out would be zero. so we do not want it . if we don't write else here it will store previously read value.
    
 end



endmodule