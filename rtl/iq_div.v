`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dependencies: Analyzes the input serial signal and differentiates it into two bipolar code outputs, I and Q.
// Each bit picks 100 points, code element rate of 5kb, so each output data rate of 250kb / s
// Sampling rate 500k, input clock 50Mhz
//////////////////////////////////////////////////////////////////////////////////
module iq_div
    #(parameter IQ_DIV_MAX = 8'd100, //Sampling rate is clk/IQ_DIV_MAX
                BIT_SAMPLE = 8'd100  //Sampling points per bit
    )
    
    (
        input wire          clk     ,
        input wire          rst_n   ,
        input wire          ser_i   ,
        
        output wire [1:0]   I       , //Signed Bipolar Outputs
        output wire [1:0]   Q
    );
    
    
    //Counter, when the count value is 1, the data of ser_i will be collected once, as a sample.
    reg [7:0]   cnt_iq_div  ;
    
    //Calculate the number of samples collected in each bit, the maximum value is 100, when BIT_SAMPLE is reached, the output channel will be switched.
    reg [7:0]   cnt_sample  ;
    
    reg         iq_switch   ;  //A value of 0 means that Q data is collected, and a value of 1 means that I data is collected.
    
    //Bit data for both I and Q outputs
    //First cache the acquired data into I_bit_temp,Q_bit_temp
    //The I_bit is then updated at the same clock using the data in the cache.
    //Aligning the two output data of IQ facilitates subsequent sampling judgments
    reg         I_bit_temp      ;
    reg         Q_bit_temp      ;
    
    reg         I_bit       ;
    reg         Q_bit       ;
    
    
    //cnt_iq_div
    //Counter, when the count value is 1, the data of ser_i will be collected once, as a sample.
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            cnt_iq_div <= 8'd0;
        end else if(cnt_iq_div == (IQ_DIV_MAX-8'd1)) begin
            cnt_iq_div <= 8'd0;
        end else begin
            cnt_iq_div <= cnt_iq_div + 8'd1;
        end
    end
    
    //cnt_sample
    //Calculate the number of samples collected in each bit, the maximum value is 100, when BIT_SAMPLE is reached, 
        //the output channel will be switched.
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            cnt_sample <= 8'd0;
        end else if((cnt_iq_div == 8'd1) && (cnt_sample == (BIT_SAMPLE - 8'd1))) begin
            cnt_sample <= 8'd0;
        end else if(cnt_iq_div == 8'd1) begin
            cnt_sample <= cnt_sample + 8'd1;
        end else begin
            cnt_sample <= cnt_sample;
        end
    end
    
    //iq_switch
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
        //The Q path is captured first, and immediately after the reset is canceled, this value will change to 1'b0, representing the Q path
            iq_switch <= 1'b1;  
        end else if((cnt_iq_div == 8'd0) && (cnt_sample == 0)) begin
            iq_switch <= ~iq_switch;
        end else begin
            iq_switch <= iq_switch;
        end
    end
    
    //I_bit  Q_bit
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            I_bit <= 1'b0;
            Q_bit <= 1'b0;
            I_bit_temp <= 1'b0;
            Q_bit_temp <= 1'b0;
        end else begin
            case(iq_switch) 
                //to the next acquisition cycle and then update it, so that the two output data of IQ are aligned, 
                        //which is favorable for subsequent sampling judgment
                //Because the first time you sample one of the two channels, the other channel is invalid.
                //In order to keep the two channels of data from being separated, it is necessary to delay one of the channels one more time.
                1'b0: begin //Capture Q channel and store it to I_bit_temp
                    I_bit <= I_bit;
                    Q_bit <= Q_bit;
                    Q_bit_temp <= ser_i;
                    I_bit_temp <= I_bit_temp;
                    
                end
                1'b1: begin //Capture I channel, store to I_bit_temp, update IQ two channels.
                    Q_bit <= Q_bit_temp;
                    I_bit <= I_bit_temp;
                    I_bit_temp <= ser_i;
                    Q_bit_temp <= Q_bit_temp;
                end             
            endcase
        end
    end
    
    
    //Converts to bipolar output
    assign I = (I_bit == 1'b0)? 2'b11:2'b01; 
    assign Q = (Q_bit == 1'b0)? 2'b11:2'b01; 
    
    
    
endmodule
