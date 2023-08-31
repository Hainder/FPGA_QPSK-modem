`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: Combine the two paths of judgmental IQ into a serial data output
//The input clock frequency is the same as the sample rate.
//////////////////////////////////////////////////////////////////////////////////
module iq_comb
#(parameter SAMPLE = 100)
    (
        input wire          clk         ,  //500kHz
        input wire          rst_n       ,
        input wire          sync_I      ,
        input wire          sync_Q      ,
        input wire          sync_flag_i ,  //Synchronization flag input from Gardner bit synchronizer
        
        output wire         demo_ser_o  ,
        output wire         sync_flag_o    //Synchronized output data to subsequent modules
        //Two sync_flag_o valid signals are required for a set of IQ data
    );
    
    // Determine whether the serial output is I or Q. 0 means Q, 1 means I.
    reg         iq_switch   ;
    wire        q2i_flag    ;
    reg         q2i_flag_d1 ;
    reg         sync_flag_i_d1;
    
    reg         sync_I_d    ;
    reg         sync_Q_d    ;
    
    
    //Calculates the number of samples and converts from output serial data from the Q channel to the I channel when SAMPLE-1 is calculated.
    reg [6:0]   sample_cnt  ;
    
    //sample_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sample_cnt <= 7'd0;
        end else if((sample_cnt == SAMPLE - 1) && !iq_switch) begin
            sample_cnt <= 7'd0;
        end else if(sync_flag_i) begin
        //A valid IQ signal arrives and is cleared and recounted.
            sample_cnt <= 7'd0;
        end else if(!iq_switch) begin  //Calculate the number of samples for Q-way data output
            sample_cnt <= sample_cnt + 7'd1;
        end else begin
            sample_cnt <= 7'd0;
        end
    end
    
    //iq_switch
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            iq_switch <= 1'b0;
        end else if(sync_flag_i) begin
        //A valid IQ signal arrives, first handing over the channel to the Q output.
            iq_switch <= 1'b0;
        end else if(q2i_flag) begin
        //Conversion from Q to I channel
            iq_switch <= 1'b1;
        end else begin
            iq_switch <= iq_switch;
        end
    end 
    
    //q2i_flag beat to get the synchronization signal, 
        //this synchronization signal and the output parallel data of the beginning of the I channel data alignment
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            q2i_flag_d1 <= 1'b0;
        end else begin
            q2i_flag_d1 <= q2i_flag;
        end
    end
    
    //Tap the input sync signal sync_flag_i to get the sync signal sync_flag_i_d1
    //And beat the output synchronization data by one beat
    //Align sync_flag_o with the changed position of the output data
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sync_flag_i_d1 <= 1'b0  ;
            sync_I_d <= 1'b0        ;
            sync_Q_d <= 1'b0        ;
        end else begin
            sync_flag_i_d1 <= sync_flag_i   ;
            sync_I_d <= sync_I              ;
            sync_Q_d <= sync_Q              ;
        end
    end
    
    //Output synchronization flag, aligned with the start point of both IQ channels
    assign sync_flag_o = sync_flag_i_d1 | q2i_flag_d1;
    
    //q2i_flag
    //Q-way data and output SAMPLE samples.
    assign q2i_flag = ((sample_cnt == SAMPLE - 1) && !iq_switch)?1'b1: 1'b0;
    
    //Alternate output channel selection based on iq_switch, output data is delayed one clock cycle from the original
    assign demo_ser_o = (iq_switch == 1'b1)? sync_I_d: sync_Q_d;
    
endmodule
