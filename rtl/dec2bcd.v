module dec2bcd(
    input wire      clk     ,
    input wire      rst_n   ,
    input wire[7:0] dec_in  ,  
    
    output reg[3:0] unit    ,
    output reg[3:0] ten     
    );
    
    parameter SHIFT_CNT_MAX = 4'd8;   //Number of shifts, consistent with the length of dec_in
    parameter BCD_BIT_CNT = 4'd8; //The number of bits in the output BCD code is also the number of complementary zeros at the beginning of the process.
    
    //The input data is first zeroed out, and the data is left-shifted every clock cycle; after the left-shift, the size of each BCD byte is increased by three if it is greater than four.
    //Repeat the above operation until all the input data is moved in, this clock experiment is to move to the left 7 times can be
    
    reg [BCD_BIT_CNT+7:0] shift_data; //The intermediate data of the process is first made up to 0
    reg [3:0]   shift_cnt;//Number of shifts
    reg         shift_flag; //Shift flag, 1 for shift, 0 for compare
    
    //shift_flag
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shift_flag <= 1'b0;         //Start at 0, load shift_data with complementary zeros
        end else begin
            shift_flag <= ~shift_flag;   //The shift operation and the judgment operation are performed sequentially
        end
    
    end
    
    //shift_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shift_cnt <= 0;
        end else if((shift_cnt == SHIFT_CNT_MAX) && shift_flag) begin  //Shift count reaches count maximum
            shift_cnt <= 0;
        end else if(shift_flag) begin
            shift_cnt <= shift_cnt + 1; 
        end else begin
            shift_cnt <= shift_cnt;
        end
    end 
    
    //shift_data, main processed data
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shift_data <= {8'b0, dec_in};  //Complementary 0 on reset
        end else if((shift_cnt == 0) && (!shift_flag)) begin  
            shift_data <= {8'b0, dec_in};  //shift_cnt = 0 and shift_flag is low, representing the start of a new round of processing
        end else if(shift_flag) begin   //(computing) a shift operation
            shift_data <= shift_data << 1;
        end else if((!shift_flag)) begin
        //Determine whether the two bcd fields > 4, if so, add 3, otherwise keep the original data
            shift_data[15:12] <= (shift_data[15:12] > 4'd4)?(shift_data[15:12] + 4'b0011):shift_data[15:12];
            shift_data[11:8] <= (shift_data[11:8] > 4'd4)?(shift_data[11:8] + 4'b0011):shift_data[11:8];            
        end else begin
            shift_data <= shift_data;
        end
    
    end
    
    //Extraction of unit data
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            unit <= 4'b0;
        end else if((shift_cnt == SHIFT_CNT_MAX) && (!shift_flag)) begin
        //Data processing is complete and the processed data is loaded for output
            unit <= shift_data[11:8];
        end else begin
            unit <= unit;
        end
    end
    
    //ten
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ten <= 4'b0;
        end else if((shift_cnt == SHIFT_CNT_MAX) && (!shift_flag)) begin
            ten <= shift_data[15:12];
        end else begin
            ten <= ten;
        end
    end 

    
endmodule
