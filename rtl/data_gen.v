//////////////////////////////////////////////////////////////////////////////////
// Dependencies: Generate 40bit data frame, parallel output
//////////////////////////////////////////////////////////////////////////////////
module data_gen
#(parameter HEADER = 8'hcc)  //header
(
    input wire [7:0]    dec_s   ,
    input wire [7:0]    dec_m   ,
    input wire [7:0]    dec_h   ,
    
    output wire [39:0]  para_o  
);

    wire [7:0]  valid   ; //checksum
    
    //The frame header is set to 1100_1100,after IQ splitting both data will be 1010, alternating 0/1 facilitates Gardner bit synchronization
    assign valid = HEADER + dec_s + dec_m + dec_h; //Calculate the checksum
    assign para_o = {HEADER, dec_h, dec_m, dec_s, valid};

endmodule
