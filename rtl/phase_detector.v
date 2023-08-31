`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2023/04/22 16:39:39
// Design Name: 
// Module Name: phase_detector
// Description: carrier synchronous phase discriminator
// 
//////////////////////////////////////////////////////////////////////////////////

module phase_detector(
        input wire  [14:0]  filtered_I  , //I low-pass filtered signal
        input wire  [14:0]  filtered_Q  , //Q-way low-pass filtered signal
        
        output wire [15:0]  phase_error   //Output phase error
    );
    
    wire [14:0] inversed_I  ;   //Inverted I channel data
    wire [14:0] inversed_Q  ;   //Inverted Q-way data
    
    //Signal of this channel determined by the symbol bit of the other channel
    reg [14:0]  channel_I   ;   
    reg [14:0]  channel_Q   ;
    
    assign inversed_I = ~filtered_I + 15'd1;  
    assign inversed_Q = ~filtered_Q + 15'd1;
    
    //channel_Q
    always @ (*) begin
        if(filtered_I[14]) begin  //negative number
            channel_Q = inversed_Q;
        end else begin
            channel_Q = filtered_Q;
        end
    end
    
    //channel_I
    //Here it is the opposite of the Q-way logic, making the original subtractor into an adder
    always @ (*) begin
        if(filtered_Q[14]) begin  //negative number
            channel_I = filtered_I;
        end else begin
            channel_I = inversed_I;
        end
    end
    
    assign phase_error = {channel_Q[14],channel_Q} + {channel_I[14],channel_I};
    
endmodule
