module gardner_sync
(
    input wire          clk         ,  //500kHz
    input wire          rst_n       ,
    input wire [14:0]   data_in_I   ,
    input wire [14:0]   data_in_Q   ,
    
    output wire         sync_out_I  ,
    output wire         sync_out_Q  ,
    output wire         sync_flag      //Best Sampling Judgment Moment Markers
);
    wire [15:0]         uk          ;  //Decimal spacing, 15bit decimal places
    wire [19:0]         I_y         ;  //Interpolation filter output I channel
    wire [19:0]         Q_y         ;  //Interpolation filter output Q-way
    wire [15:0]         wn          ;  //Error data after passing through the loop filter
    wire                strobe_flag ;  //NCO overflow flag, representing the moment of valid interpolated data
    
    
    //Interpolation filters
    interpolate_filter interpolate_filter_inst
    (
        .clk            (clk        ),
        .rst_n          (rst_n      ),
        .data_in_I      (data_in_I  ),
        .data_in_Q      (data_in_Q  ),
        .uk             (uk         ),  //Decimal spacing, 15bit decimal places

        .I_y            (I_y        ),  //I-interpolated outputs
        .Q_y            (Q_y        )       //Q-way interpolation output
    );
    
    
    //gardner timing error detection, including loop filters
    gardner_ted gardner_ted_inst
    (
        .clk                (clk            ),  //500kHz
        .rst_n              (rst_n          ),
        .strobe_flag        (strobe_flag    ),  //Valid Interpolation Flags
        .interpolate_I      (I_y            ),  //I-channel data from interpolation filters
        .interpolate_Q      (Q_y            ),  //Q-way data from the interpolation filter

        .sync_out_I         (sync_out_I     ),  //I-channel data after synchronization
        .sync_out_Q         (sync_out_Q     ),  //I-channel data after synchronization
        .sync_flag          (sync_flag      ),  //Synchronization flag, indicating that the optimal judgment point has been reached for subsequent data sampling
        .wn                 (wn             )   //Error data after passing through the loop filter
    );
    
    //nco module
    nco nco_inst
    (
        .clk            (clk        ),
        .rst_n          (rst_n      ),
        .wn             (wn         ),  //w(n) of the loop filter output, with the lower 15bit being the fractional bit

        .strobe_flag    (strobe_flag),  //Overflow signal from nco output, representing the effective interpolation moment
        .uk             (uk         )   //Output to the interpolation filter decimal interval, the lower 15 bits are decimal places
    );
    
    
    


endmodule