//Delay    Meaning              When to use
──────────────────────────────────────────────
//#10      half clock cycle     back to back operations changing data_in small gaps between signals
//#20      one full clock       single operation pulse signal high then low gap after reset
//#30      one and half cycles  settling time after reset  safe gap before first operation     
//#100     5 full cycles        final wait before $finish  lets last operations complete
                             


//Always give at least one full clock cycle for any operation to complete.
//#20 minimum for any meaningful action.
//#10 only for back to back same operation.
//#30 or more when crossing important boundaries like reset release.



`timescale 1ns/1ps

module fifo_tb;

reg [7:0]data_in;
reg wr_en, rd_en;
wire full , empty;
reg clk, reset;
wire [7:0]data_out;


fifo_top dut(.clk(clk) ,.reset(reset) ,.data_in(data_in),.wr_en(wr_en),.rd_en(rd_en),.full(full),.empty(empty) ,.data_out(data_out));

initial clk=0;
always #10 clk=~clk;



//case 1 test
initial begin
     reset =1;
     #20 reset = 0;

     //data gets overwritten between tests. That is intentional. Each test only cares about what it just wrote. 
     //The pointer system ensures only valid data is read, regardless of what physically sits in old slots.

    //Test 1 = writes and read data
   #30 wr_en=1 ;data_in=8'b10100011 ; 
   #20 wr_en = 0 ;
   #10 rd_en = 1;
   #20 rd_en = 0;

   //Test 2 = writes all slots 

   #10 wr_en =1 ; data_in=8'b10101010; 
   #10 wr_en =1 ; data_in=8'b10101001;
   #10 wr_en =1 ; data_in=8'b00101010;
   #10 wr_en =1 ; data_in=8'b10001010;
   #10 wr_en =1 ; data_in=8'b10111010;
   #10 wr_en =1 ; data_in=8'b10101110;
   #10 wr_en =1 ; data_in=8'b00000010;
   #10 wr_en =1 ; data_in=8'b11111111;
   #10 wr_en =0 ;

   //Test 3 = Read all slots written in test 2 . it is draining.
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   
   //Test 4 =Read and Write at the same time
   #10 wr_en=1 ;data_in=8'b10100011 ; rd_en =1 ;
   #10 wr_en =1 ; data_in=8'b10101010; rd_en =1;
   #10 wr_en=0 ; rd_en =0;

   //Test 5 = wrapping . write 4 slots and read 4 slots and again write 4 slots to check after 4 slots when write and read pointer is at the same position , it can fill the slot 5,6 and so on perfectly.
   #10 wr_en =1 ; data_in=8'b10101010;
   #10 wr_en =1 ; data_in=8'b10101011;
   #10 wr_en =1 ; data_in=8'b10101001;
   #10 wr_en =1 ; data_in=8'b10100110;
   #10 wr_en =0;

   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;

   #10 wr_en =1 ; data_in=8'b10111010;
   #10 wr_en =1 ; data_in=8'b10101110;
   #10 wr_en =1 ; data_in=8'b00000010;
   #10 wr_en =1 ; data_in=8'b11111111;
   #10 wr_en =0 ;

   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
   #20  rd_en =1; #20 rd_en = 0;
#100 $finish;

end

initial begin

    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, fifo_tb);

    $monitor("t=%0t  wr_en =%b  rd_en =%b data_in=%b  data_out=%b full=%b empty=%b" , $time ,wr_en , rd_en , data_in , data_out , full ,empty);
    
end

endmodule