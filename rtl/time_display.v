`timescale 1ns / 1ps
//Parses and dynamically displays hour, minute, and second data from 40bit data on a digital tube.
module time_display
(
    input   wire        clk     ,
    input   wire        rst_n   ,
    input   wire[39:0]  dat_i   ,
    
    output  wire[5:0]   sel     ,  //Digital tube selection signal
    output  wire[7:0]   dig        //Digital tube data
);
    //Raw data of hours, minutes and seconds
    wire [7:0]      dec_h       ;
    wire [7:0]      dec_m       ;
    wire [7:0]      dec_s       ;
    
    //bcd data for hours, minutes and seconds
    wire [3:0]      bcd_h_ten   ;
    wire [3:0]      bcd_h_unit  ;
    wire [3:0]      bcd_m_ten   ;
    wire [3:0]      bcd_m_unit  ;
    wire [3:0]      bcd_s_ten   ;
    wire [3:0]      bcd_s_unit  ;
    
    //Parse hour, minute and second according to the corresponding data bits
    assign dec_h = dat_i[31:24] ;
    assign dec_m = dat_i[23:16] ;
    assign dec_s = dat_i[15:8]  ;
    
    
    //Convert raw data to BCD code
    //hour
    dec2bcd dec2bcd_h(
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dec_in     (dec_h  ),  

        .unit       (bcd_h_unit ),
        .ten        (bcd_h_ten  )   
    );
    
    //ingredient
    dec2bcd dec2bcd_m(
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dec_in     (dec_m  ),  

        .unit       (bcd_m_unit ),
        .ten        (bcd_m_ten  )   
    );
    
    //unit of angle or arc equivalent one sixtieth of a degree
    dec2bcd dec2bcd_s(
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dec_in     (dec_s  ),  

        .unit       (bcd_s_unit ),
        .ten        (bcd_s_ten  )   
    );
    
    //Digital tube display control signal generation
    seg_display 
    #(.CNT_SEL_MAX(10'd999))
    seg_display_inst
    (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .in0        (bcd_s_unit ),
        .in1        (bcd_s_ten  ),
        .in2        (bcd_m_unit ),
        .in3        (bcd_m_ten  ),
        .in4        (bcd_h_unit ),
        .in5        (bcd_h_ten  ),

        .sel        (sel    ),
        .dig        (dig    )
    );

    
endmodule
