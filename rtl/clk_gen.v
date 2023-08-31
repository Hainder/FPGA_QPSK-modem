module clk_gen
#(parameter CNT_MAX = 26'd49_999_999)
(
    input wire          clk     ,  //50Mhz clock
    input wire          rst_n   ,
    
    output reg[7:0]     s_dec   ,
    output reg[7:0]     m_dec   ,
    output reg[7:0]     h_dec       
    );
    
    reg [25:0] cnt;     //Used for timing, as standard
    
    
    //cnt
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 26'd0;
        end else if(cnt == CNT_MAX) begin
            cnt <= 26'd0;
        end else begin
            cnt <= cnt + 26'd1;
        end
    end
    
    //s_dec
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            s_dec <= 8'd0;
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59)) begin  //Seconds count to 59.
            s_dec <= 8'd0;
        end else if(cnt == CNT_MAX) begin  //Increments itself when 1 second is reached without counting to the maximum value.
            s_dec <= s_dec + 8'd1;
        end else begin
            s_dec <= s_dec;
        end
    end
    
    //m_dec
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            m_dec <= 8'd0;
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59) && (m_dec == 8'd59)) begin  //Count to 59 and fulfill the jump condition
            m_dec <= 8'd0;
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59)) begin  //Self-increment when the second hand is cleared without counting to the maximum value.
            m_dec <= m_dec + 8'd1;
        end else begin
            m_dec <= m_dec;
        end
    end 
    
    //h_dec
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            h_dec <= 8'd0;
            //The time count reaches 23:59:59 and meets the jump condition
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59) && (m_dec == 8'd59) && (h_dec == 8'd23)) begin  
            h_dec <= 8'd0;
            //Self-increment when the minute and second hands are cleared without counting to the maximum value.
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59) && (m_dec == 8'd59)) begin  
            h_dec <= h_dec + 8'd1;
        end else begin
            h_dec <= h_dec;
        end
    end     
    
endmodule
