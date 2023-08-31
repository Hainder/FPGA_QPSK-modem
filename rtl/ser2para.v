//////////////////////////////////////////////////////////////////////////////////
// Description: Converts demodulated serial data output to 40bit parallel data
//The input clock frequency is the same as the sample rate.
//////////////////////////////////////////////////////////////////////////////////
module ser2para
    #(parameter SAMPLE = 100) //Number of samples per bit 
    (
        input wire          clk     ,
        input wire          rst_n   ,
        input wire          ser_i   ,
        
        output reg [39:0]   para_o
    );
    
    reg [7:0]   sample_cnt  ;
    reg [5:0]   bit_cnt     ;
    
    //Parallel output data processed temporarily and given to para_o after the 40bit conversion is complete
    reg [39:0]  para_o_temp ; 
    
    
    //sample_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sample_cnt <= 8'd0;
        end else if(sample_cnt == (SAMPLE - 1)) begin
            sample_cnt <= 8'd0;
        end else begin
            sample_cnt <= sample_cnt + 8'd1;
        end
    end
    
    //bit_cnt
    //Set to capture a bit of para_o at sample_cnt == (SAMPLE - 3)
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            bit_cnt <= 6'd38;  //Since the previous sampling judgment moments are in the middle of the data, there is a time difference of two bits in the input serial data
        end else if((bit_cnt == 6'd39) && sample_cnt == (SAMPLE - 3)) begin
            bit_cnt <= 6'd0;
        end else if(sample_cnt == (SAMPLE - 3))begin
            bit_cnt <= bit_cnt + 6'd1;
        end else begin
            bit_cnt <= bit_cnt;
        end
    end
    
    //para_o_temp
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            para_o_temp <= 40'b0;
        end else if(sample_cnt == (SAMPLE - 3)) begin
            para_o_temp[39-bit_cnt] <= ser_i;
        end else begin
            para_o_temp <= para_o_temp;
        end 
    end
    
    //para_o
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            para_o <= 40'b0;
        end else if(sample_cnt == (SAMPLE - 2) && (bit_cnt == 6'd0)) begin //Delayed by one clock cycle from the completion of para_o_temp acquisition
            para_o <= para_o_temp;
        end else begin
            para_o <= para_o;
        end
    end

endmodule
