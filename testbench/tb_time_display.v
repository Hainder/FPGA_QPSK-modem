`timescale 1ns / 1ps
module tb_time_display();
    reg         clk     ;
    reg         rst_n   ;
    reg [39:0]  dat_i   ;
    
    wire[5:0]   sel     ;
    wire[7:0]   dig     ;
    
    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        //data whose header and checksum are correct
        //23:24:25
        dat_i <= 40'b1100_1100_0001_0111_0001_1000_0001_1001_0001_0100;
    #20 
        rst_n <= 1'b1;
    end
    
    always #10 clk = ~clk;
    
    
    
    time_display time_display_inst
    (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dat_i      (dat_i  ),

        .sel        (sel    ),  //Digital tube selection signal
        .dig        (dig    )   //Digital tube data
    );
endmodule
