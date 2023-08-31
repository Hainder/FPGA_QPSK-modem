`timescale 1ns / 1ps
module tb_iq_comb();
    reg         clk         ;
    reg         rst_n       ;
    reg         sync_I      ;
    reg         sync_Q      ;
    reg         sync_flag_i ;  
    
    wire        demo_ser_o  ;
    wire        sync_flag_o ;

    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        sync_flag_i <= 1'b0;
        sync_I <= {$random} % 2;  //Generate 0-1 random numbers
        sync_Q <= {$random} % 2;    
    #2000
        rst_n <= 1'b1;
        sync_flag_i <= 1'b1;
        sync_I <= 1'b1;  //First set of IQ data
        sync_Q <= 1'b0; 
    #2000 //The sync_flag_i signal is maintained 1 clock cycle at a time in this case
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= 1'b1;  //Second set of IQ data
        sync_Q <= 1'b0;
    #2000 //The sync_flag_i signal is maintained 1 clock cycle at a time in this case
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= {$random} % 2;  //Third set of IQ data
        sync_Q <= {$random} % 2;
    #2000 //The sync_flag_i signal is maintained 1 clock cycle at a time in this case
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= {$random} % 2;  //Fourth set of IQ data
        sync_Q <= {$random} % 2;
    #2000 //The sync_flag_i signal is maintained 1 clock cycle at a time in this case
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= {$random} % 2;  //Group V IQ data
        sync_Q <= {$random} % 2;
    #2000 //The sync_flag_i signal is maintained 1 clock cycle at a time in this case
        sync_flag_i <= 1'b0;
    end
    
    always #1000 clk = ~clk; //500kHz clock

    iq_comb 
    #(.SAMPLE(100))
    iq_comb_inst
    (
        .clk            (clk        ),
        .rst_n          (rst_n      ),
        .sync_I         (sync_I     ),
        .sync_Q         (sync_Q     ),
        .sync_flag_i    (sync_flag_i),  //Synchronization flag input from Gardner bit synchronizer

        .demo_ser_o     (demo_ser_o ),
        .sync_flag_o    (sync_flag_o)   //Synchronized output data to subsequent modules
    );
    
endmodule
