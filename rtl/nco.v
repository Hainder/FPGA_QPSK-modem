//NCO module to generate strobe signals and fractional intervals
module nco
(
    input wire          clk         ,
    input wire          rst_n       ,
    input wire [15:0]   wn          ,  //w(n) of the loop filter output, with the lower 15bit being the fractional bit
    
    output reg          strobe_flag ,  //Overflow signal from nco output, representing the effective interpolation moment
    output reg [15:0]   uk             //Output to the interpolation filter decimal interval, the lower 15 bits are decimal places
);
    reg [16:0]   nco_reg_eta        ;  //nco register η
    wire         eta_overflow       ;  //nco register η overflow flag
    wire[16:0]   eta_temp           ;  //The intermediate computed data of the nco register η may be negative, and a negative value requires a mod1 operation to update the nco register η.

    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            nco_reg_eta <= 17'b0_0110_0000_0000_0000    ;   //The initial value of the nco register is set to 1
            uk <= 16'b0100_0000_0000_0000               ;   //The initial value of the score interval is set to 0.5
            strobe_flag <= 1'b0;
        end else if(eta_overflow) begin //nco overflow
            strobe_flag <= 1'b1;
            // η(mk+1) = η(mk) - wn + 1
            //Updating the nco register by mod1 operation
            nco_reg_eta <= eta_temp + 17'b0_1000_0000_0000_0000;
            
            //Calculate the decimal interval
            //μk≈2η(mk) 
            uk <= {nco_reg_eta[15:0],1'b0};  
        end else begin
            strobe_flag <= 1'b0;
            nco_reg_eta <= eta_temp;  //The nco register is decremented each clock cycle wn
            uk <= uk;
        end
    end
    
    assign eta_temp = nco_reg_eta - {wn[15],wn};
    assign eta_overflow = eta_temp[16];  //A sign bit of 1 indicates a negative value, nco overflow
    

endmodule