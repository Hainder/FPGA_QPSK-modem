
//////////////////////////////////////////////////////////////////////////////////
// Dependencies: Converts input 40bit parallel data to serial output
// High First Out for Parallel Data
// Output code element rate is clk/DIV
// Default configuration: clk is 50MHz, DIV = 10000, output code rate is 5kHz.
//////////////////////////////////////////////////////////////////////////////////
module para2ser
    #(parameter DIV = 14'd10000)
    (
        input wire          clk         ,
        input wire          rst_n       ,
        input wire  [39:0]  para_i      ,
        
        output reg          ser_o       
    );
    
    //Timer, each time count to DIV-1,ser_o update 1bit data
    reg [13:0]  div_cnt;  
    
    //Record the current bit to be output
    reg [5:0]   bit_cnt;
    
    //div_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            div_cnt <= 14'd0;
        end else if(div_cnt == DIV - 1) begin
            div_cnt <= 14'd0;
        end else begin
            div_cnt <= div_cnt + 14'd1;
        end
    end
    
    //bit_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            bit_cnt <= 6'd0;
        end else if((bit_cnt == 6'd39) && (div_cnt == DIV - 1)) begin
            bit_cnt <= 6'd0;
        end else if(div_cnt == DIV - 1) begin
            bit_cnt <= bit_cnt + 14'd1;
        end else begin
            bit_cnt <= bit_cnt;
        end
    end
    
    // ser_o
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            ser_o <= 1'b0;
        end else begin
            ser_o <= para_i[39 - bit_cnt];
        end
    end
    
    
    
    
endmodule
