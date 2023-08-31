`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: Verification of correct data according to the set frame header and checksum.
// The frame header in this design is 8'b1100_1100
//////////////////////////////////////////////////////////////////////////////////
module data_valid
#(parameter HEADER = 8'b1100_1100)
(
    input wire          clk         ,  //500KHz
    input wire          rst_n       ,
    input wire          ser_i       ,  //Serial data input from iq_comb module
    input wire          sync_flag   ,  //synchronization flag
    
    output wire         header_flag ,  //Correct frame header detected
    output wire         valid_flag  ,  //The header and checksum are correct flags for valid data.
    output reg  [39:0]  valid_data_o   //Parallel output of valid data
);
    reg [39:0]  shift_reg   ;       //Shift register, registers incoming serial data
    wire [7:0]  sum         ;       //The checksum obtained by calculating
    
    wire    check_sum_valid_flag    ; //Checksum Correct Flag
    
    //shift register
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            shift_reg <= 40'b0;
        end else if(sync_flag) begin
            shift_reg <= {shift_reg[38:0],ser_i}; //IQ data is sent first, so the received data is shifted from low to high.
        end else begin
            shift_reg <= shift_reg;
        end
    end
    
    //valid_data_o
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            valid_data_o <= 40'b0;
        end else if(valid_flag) begin
            valid_data_o <= shift_reg;
        end else begin
            valid_data_o <= valid_data_o;
        end
    end
    
    //header flags
    assign header_flag = (shift_reg[39:32] == HEADER);
    assign sum = shift_reg[39:32] + shift_reg[31:24] + shift_reg[23:16] + shift_reg[15:8];
    assign check_sum_valid_flag = (sum == shift_reg[7:0])?1'b1: 1'b0;  //checksum
    assign valid_flag = header_flag & check_sum_valid_flag; //Checksums and headers are correct.
    

    
    

endmodule
