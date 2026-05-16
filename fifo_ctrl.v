//It is the control logic block .
// It decides when the data is stored based on the request by the user or anything . it is manager and gives command.
 `timescale 1ns/1ps
 
module fifo_ctrl(input wr_en , rd_en , clk, reset, output [2:0] wr_addr , rd_addr, output full , empty , wr_en_mem , rd_en_mem);

reg [3:0] wr_ptr , rd_ptr;        //they are not included in ports because they do not come from outside world. It's for internal purpose.
                                  //the 4 bit pointers are used because the 4th bit i.e MSB will tell whether the fifo is full or not.


// Below four assign are not included in always block becoz we want these continuously. 
//If i put them in always block then they will take their decision at the clock edge and other dependent "if" statements will not get executed  at the clock edge.

assign empty = wr_ptr ==rd_ptr;  
assign full = (wr_ptr[2:0] == rd_ptr[2:0] ) && (wr_ptr[3]!=rd_ptr[3]);    //msb doesnot match ---KEY for full condition

assign wr_addr[2:0]= wr_ptr[2:0];           // It tells the mem to take pointers 3 bits only for address.
assign rd_addr[2:0]= rd_ptr[2:0];

assign wr_en_mem = wr_en && !full;
assign rd_en_mem =  rd_en && !empty;


always@(posedge clk)begin

     if(reset) begin     // Reset comes first becoz reset is checked first and then other parts can be executed . if i put reset at last then all the data will get erased.

        wr_ptr <=0;
        rd_ptr <=0;
    end
    else begin

       if(wr_en && !full) begin
        wr_ptr <= wr_ptr+1;
        
        end
        if(rd_en && !empty) begin
        rd_ptr <= rd_ptr+1;
        end
    
    end

    end


endmodule