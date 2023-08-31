`timescale 1ns / 1ps
//Top-level module that generates clock data and transmits it to and from the QPSK modem.
//In this example, QPSK modulation is implemented on the same FPGA device.
module qpsk_clk_top
#(parameter HEADER = 8'hcc,   //header
            CNT_MAX = 26'd49_999_999) //Test speed, under normal circumstances set to 26'd49_999_999 when every 1s to update data
(
    input wire          clk         ,  //50MHz
    input wire          rst_n       ,
    
    output wire [5:0]   sel         ,
    output wire [7:0]   dig         
);
    wire [32:0]         qpsk    ;
    wire [7:0]          s_dec   ;  //data in seconds
    wire [7:0]          m_dec   ;  //data in minutes
    wire [7:0]          h_dec   ;  //data in hours
    wire [39:0]         para_dat;
    wire [39:0]         para_out;   //Output data, including hours, minutes and seconds


    
    
    //Generate hour, minute and second data
    clk_gen 
    #(.CNT_MAX(CNT_MAX))  
    clk_gen_inst
    (
        .clk        (clk    ),  //50Mhz clock
        .rst_n      (rst_n  ),

        .s_dec      (s_dec  ),
        .m_dec      (m_dec  ),
        .h_dec      (h_dec  )   
    );
    
    //Add the data to the data frame header and checksum to form 40 bit data
    data_gen
    #(.HEADER(HEADER))  //header
    data_gen_inst
    (
        .dec_s  (s_dec  ),
        .dec_m  (m_dec  ),
        .dec_h  (h_dec  ),

        .para_o (para_dat)
    );
    
    
    //modem
    qpsk_mod qpsk_mod_inst
    (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .para_in    (para_dat   ),

        .qpsk       (qpsk       )
    );
    
    //demodulate
    qpsk_demod 
    #(.HEADER(HEADER))  //header    
    qpsk_demod_inst
    (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .qpsk       (qpsk[21:0] ),  //After simulation it was confirmed that the high position was not used to

        .para_out   (para_out   )   //Parallel data output after demodulation
    );
    
    //Digital display of demodulated time data.
    time_display time_display
    (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dat_i      (para_out),

        .sel        (sel    ),  //Digital tube selection signal
        .dig        (dig    )   //Digital tube data
    );
endmodule
