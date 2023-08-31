`timescale 1ns / 1ps
module tb_data_gen();
    wire [7:0] dec_h;
    wire [7:0] dec_m;   
    wire [7:0] dec_s;
    
    wire [39:0] para_o;
    
    assign dec_h = 8'd23;
    assign dec_m = 8'd24;
    assign dec_s = 8'd25;
    
    //23 hours, 24 minutes, 25 seconds.

    data_gen 
    #(.HEADER(8'hcc))  //header 
    data_gen_inst
    (
        .dec_s  (dec_s  ),
        .dec_m  (dec_m  ),
        .dec_h  (dec_h  ),

        .para_o (para_o )
    );

endmodule
