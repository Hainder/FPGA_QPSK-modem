//Calculate the timing error using gardner's algorithm and obtain fractional intervals by loop filtering
//Simultaneously derive the two output data for the best judgment point
module gardner_ted
(
    input wire          clk             ,  //500kHz
    input wire          rst_n           ,
    input wire          strobe_flag     ,  //Valid Interpolation Flags
    input wire [19:0]   interpolate_I   ,  //I-channel data from interpolation filters
    input wire [19:0]   interpolate_Q   ,  //Q-way data from the interpolation filter
    
    output reg          sync_out_I      ,  //I-way data after judgment
    output reg          sync_out_Q      ,  //Q-way data after judgment
    output reg          sync_flag       ,  //Synchronization flag, representing that the best judgment point has arrived, aligned with the output judgment data
    output reg [15:0]   wn                 //Error data after passing through the loop filter
);

    reg [21:0]  error               ; //Time error calculated by gardner's algorithm
    //For error data caching
    reg [21:0]  error_d1            ;
    
    //Number of times strobe_flag has been hosted
    reg [7:0]   strobe_cnt          ;
    
    
    //Sampling data cache for error calculation
    reg [19:0]  interpolate_I_d1    ;  
    reg [19:0]  interpolate_I_d2    ;   
    reg [19:0]  interpolate_Q_d1    ;
    reg [19:0]  interpolate_Q_d2    ;

    wire        samp_flag           ;
    
    //sync_flag is samp_flag by one beat, so that sync_flag is exactly aligned with the output data after the judgment.
    //Subsequent acquisition of judgment data when sync_flag is high is sufficient
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sync_flag <= 1'b0;
        end else begin
            sync_flag <= samp_flag;
        end
    end

    
    
    //Best Sampling Judgment Moment Markers
    //The NCO outputs the first strobe_flag when it has reached the first optimal pumping judgment moment
    //Therefore, strobe_cnt == 0 and strobe_flag arrives high to represent the best moment to draw judgment.
    assign samp_flag = ((strobe_cnt == 0) && strobe_flag)?1'b1: 1'b0;
    
    
    //The number of times strobe_flag is counted, and also the number of times nco overflows, 
        //strobe_flag occurs at the optimal draw judgment moment as well as at the central optimal draw judgment moment
    //strobe_cnt counts between 0 and 1 in this case
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            strobe_cnt <= 8'd0;
        end else if((strobe_cnt == 1) && strobe_flag) begin
            strobe_cnt <= 8'd0;
        end else if(strobe_flag) begin
            strobe_cnt <= strobe_cnt + 8'd1;
        end else begin
            strobe_cnt <= strobe_cnt;
        end
    end
    

    //Collecting data at the optimal moment of judgment as well as at intermediate moments
    //Calculation of errors based on Gardner's algorithm
    //The error needs to be calculated only once for each code element symbol
    //and the resulting time error data is filtered through the loop to obtain the fractional interval
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            interpolate_I_d1 <= 20'b0;
            interpolate_I_d2 <= 20'b0;
            interpolate_Q_d1 <= 20'b0;
            interpolate_Q_d2 <= 20'b0;
            
            //Here the loop filter output w(n) has an initial value of ≈1/100, the
            //100 represents half of the number of samples per code element (200 in this case) of I\Q road data
            wn <= 16'b0000_0001_0100_0111;  
            error <= 22'b0;
            error_d1 <= 22'b0;

        end else if(strobe_flag) begin
            //The Best Moment of Judgment and the Moment Between Moments of Judgment Arrive
            //Update the data used to calculate the error
            interpolate_I_d1 <= interpolate_I;
            interpolate_I_d2 <= interpolate_I_d1;

            interpolate_Q_d1 <= interpolate_Q;
            interpolate_Q_d2 <= interpolate_Q_d1;
            
            if(samp_flag) begin
            //The best moment of judgment has arrived.
            //Calculate and update timing errors
            //μt(k)=I(k-1/2)[I(k)−I(k−1)]
            //Depending on the sign bit, *2 and *(-2) are realized by shifting operations.
                case({interpolate_I[19],interpolate_I_d2[19],interpolate_Q[19],interpolate_Q_d2[19]})
                    4'b1010:begin
                        //IQ both ways [I(k)-I(k-1)] < 0 ,both ways take the middle value *(-2) and add to get error
                        //Symbol bits need to be extended
                        error <= ~({interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0})+20'b1 + ~({interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0})+20'b1;
                    end
                    4'b1001:begin
                        //I path [I(k)-I(k-1)]<0,Q path [I(k)-I(k-1)]>0,
                        //I road will be the middle value *(-2), Q road will be the middle value *2
                        error <= ~({interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0})+20'b1 + {interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0};
                    end
                    4'b0110: begin
                        //I path [I(k)-I(k-1)]>0,Q path [I(k)-I(k-1)]<0,
                        //I road will be the median value *2, Q road will be the median value *(-2)
                        error <= {interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0} + ~({interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0})+20'b1;
                    end
                    4'b0101:begin
                        //I path [I(k)-I(k-1)]>0,Q path [I(k)-I(k-1)]>0,
                        //I road will be the middle value *2, Q road will be the middle value *2
                        error <= {interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0} + {interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0};                   
                    end
                    4'b0100,4'b0111:begin
                        //I path [I(k)-I(k-1)] > 0,Q path [I(k)-I(k-1)] = 0
                        //I road will be the middle value *2
                        error <= {interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0};
                    end
                    4'b1000,4'b1011:begin
                        //I path [I(k)-I(k-1)] < 0, Q path [I(k)-I(k-1)] = 0
                        //I-way will be the median *(-2)
                        error <= ~({interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0})+20'b1;
                    end
                    4'b0001,4'b1101:begin
                        //I path [I(k)-I(k-1)]=0,Q path [I(k)-I(k-1)]>0
                        //Q-way will be median *2
                        error <= {interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0};                        
                    end
                    4'b0010,4'b1110:begin
                        //I path [I(k)-I(k-1)]=0,Q path [I(k)-I(k-1)]<0
                        //Q-way will be the median *(-2)
                        error <= ~({interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0})+20'b1;
                    end
                    default: begin
                        error <= 22'b0;
                    end
                endcase
            //The judgment data is output, and the judgment threshold is set to 0, so the judgment sign bit can be used.
                sync_out_I <= ~interpolate_I[19];
                sync_out_Q <= ~interpolate_Q[19];
            //The error data is updated once per optimal judgment moment
                error_d1 <= error;
                
            //Calculating fractional intervals through loop filters
            //w(ms+1)=w(ms)+c1*(err(ms)-err(ms-1))+c2*err(ms), c1 = 2^(-8)， c2≈0
                wn = wn + ({{2{error[21]}},error[21:8]}-{{2{error_d1[21]}},error_d1[21:8]});
            end
            
        end else begin
            //Other moments of data remain unchanged
            interpolate_I_d1 <= interpolate_I_d1;
            interpolate_I_d2 <= interpolate_I_d2;
            interpolate_Q_d1 <= interpolate_Q_d1;
            interpolate_Q_d2 <= interpolate_Q_d2;
        end
    end
    
    


endmodule
