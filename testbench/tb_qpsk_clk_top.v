`timescale 1ns / 1ps
module tb_qpsk_clk_top();
    reg         clk     ;
    reg         rst_n   ;
    
    wire [5:0]  sel     ;
    wire [7:0]  dig     ;

    
    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
    #30
        rst_n <= 1'b1;
    end
    
    always #10 clk = ~clk;
    
    qpsk_clk_top
    #(.HEADER(8'hcc),    //header
      .CNT_MAX(26'd49_999_99)) //Data updated once every 100ms in simulation
    qpsk_clk_top_inst
    (
        .clk            (clk    ),  //50MHz
        .rst_n          (rst_n  ),

        .sel            (sel    ),
        .dig            (dig    )
    );
endmodule
