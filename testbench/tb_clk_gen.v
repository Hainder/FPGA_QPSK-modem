`timescale 1ns / 1ps
module tb_clk_gen();

    reg         clk         ;
    reg         rst_n       ;
    
    wire    [7:0]     s_dec ;
    wire    [7:0]     m_dec ;
    wire    [7:0]     h_dec ;
    
    
    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        
        #300
        rst_n <= 1'b1;
    end

    always #10 clk = ~clk;  //50MegHz clock



    clk_gen
    #(.CNT_MAX(26'd49)) //CNT_MAX defined by the module is 26'd49_999_999,1s to complete one cycle
    //Modulesim test changed to 49, speed increased by 1Meg, equivalent to 1ms time second value will be updated
    clk_gen_inst
    (
        .clk        (clk    ),
        .rst_n      (rst_n  ),

        .s_dec      (s_dec  ),
        .m_dec      (m_dec  ),
        .h_dec      (h_dec  )
        );
endmodule
