module qpsk_demod
    #(parameter HEADER = 8'hcc)  //header
    (
        input wire          clk     ,
        input wire          rst_n   ,
        input wire  [21:0]  qpsk    ,
        
        output wire [39:0]  para_out
    );
    
    wire        clk_500k    ; 
    wire [7:0]  carry_sin   ;
    wire [7:0]  carry_cos   ;
    wire [29:0] demo_I      ;
    wire [29:0] demo_Q      ;
    wire [47:0] filtered_I  ;
    wire [47:0] filtered_Q  ;   
    wire        sync_I      ;
    wire        sync_Q      ;
    wire        sync_flag   ;
    wire        sync_flag_d1; 
    wire        demo_ser_o  ;
    wire        header_flag ;
    wire        valid_flag  ;
    wire [15:0] phase_error ;
    wire [7:0]  carry_sin_unfixed;
    wire [7:0]  carry_cos_unfixed;
    wire [7:0]  carry_sin_fixed;
    wire [7:0]  carry_cos_fixed;

    //Generates 500kHz sample clock
    sam_clk_gen sam_clk_gen_inst(
            .clk        (clk    ),  //50MHz
            .rst_n      (rst_n  ),

            .clk_o      (clk_500k)
        );
    
    //Generate cos waveforms
    dds_demo_cos dds_demo_cos (
        .aclk(clk_500k),                                  // input wire aclk
        .aresetn(rst_n),                            // input wire aresetn
        .s_axis_config_tvalid(1'b1),  // input wire s_axis_config_tvalid
        .s_axis_config_tdata({{8{phase_error[15]}},phase_error}),    // input wire [23 : 0] s_axis_config_tdata
        //.s_axis_config_tdata(phase_error + 23'b000110011001100110011001),
        .m_axis_data_tvalid(),      // output wire m_axis_data_tvalid
        .m_axis_data_tdata(carry_cos_unfixed),        // output wire [7 : 0] m_axis_data_tdata
        .m_axis_phase_tvalid(),    // output wire m_axis_phase_tvalid
        .m_axis_phase_tdata()      // output wire [23 : 0] m_axis_phase_tdata
    );
    
    //Generate sin waveform
    dds_demo_sin dds_demo_sin_inst (
        .aclk(clk_500k),                                  // input wire aclk
        .aresetn(rst_n),                            // input wire aresetn
        .s_axis_config_tvalid(1'b1),  // input wire s_axis_config_tvalid
        .s_axis_config_tdata({{8{phase_error[15]}},phase_error}),    // input wire [23 : 0] s_axis_config_tdata
        .m_axis_data_tvalid(),      // output wire m_axis_data_tvalid
        .m_axis_data_tdata(carry_sin_unfixed),        // output wire [7 : 0] m_axis_data_tdata
        .m_axis_phase_tvalid(),    // output wire m_axis_phase_tvalid
        .m_axis_phase_tdata()      // output wire [23 : 0] m_axis_phase_tdata
    );
    
    dds_fixer  u_dds_sin_fixer_i0 (
        .carry               ( carry_sin_unfixed ),//carry_sin         ),
        .carry_fixed         ( carry_sin_fixed   )
    );
    dds_fixer  u_dds_cos_fixer_i0 (
        .carry               ( carry_cos_unfixed ),
        .carry_fixed         ( carry_cos_fixed   )
    );

    assign carry_sin = carry_sin_unfixed;
    assign carry_cos = carry_cos_unfixed;

    //I-way multiplied by coherent carrier cos
    mul_demo mul_demo_I(
        .CLK(clk_500k),  // input wire CLK
        .A(qpsk),      // input wire [21 : 0] A
        .B(carry_cos),      // input wire [7 : 0] B
        .P(demo_I)      // output wire [29 : 0] P
    );  

    //Q-way times coherent carrier sin
    mul_demo mul_demo_Q(
        .CLK(clk_500k),  // input wire CLK
        .A(qpsk),      // input wire [21 : 0] A
        .B(carry_sin),      // input wire [7 : 0] B
        .P(demo_Q)      // output wire [29 : 0] P
    );  
    
    //I-way modulated signals are low-pass filtered
    demo_lowpass demo_lowpass_I (
        .aclk(clk_500k),            // input wire aclk
        .s_axis_data_tvalid(1'b1),  // input wire s_axis_data_tvalid
        .s_axis_data_tready(),  // output wire s_axis_data_tready
        .s_axis_data_tdata(demo_I[23:0]),    // 经过仿真确认demo_I高位没有使用
        .m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
        .m_axis_data_tdata(filtered_I)    // output wire [47 : 0] m_axis_data_tdata
    );
    
    //Q-way modulated signals are low-pass filtered
    demo_lowpass demo_lowpass_Q (
        .aclk(clk_500k),            // input wire aclk
        .s_axis_data_tvalid(1'b1),  // input wire s_axis_data_tvalid
        .s_axis_data_tready(),  // output wire s_axis_data_tready
        .s_axis_data_tdata(demo_Q[23:0]),    // input wire [23 : 0] s_axis_data_tdata
        .m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
        .m_axis_data_tdata(filtered_Q)    // output wire [47 : 0] m_axis_data_tdata
    );  
    
    //phase discriminator
    phase_detector phase_detector_inst(
        .filtered_I     (filtered_I[42:28]  ), //I low-pass filtered signal
        .filtered_Q     (filtered_Q[42:28]  ), //Q-way low-pass filtered signal

        .phase_error    (phase_error        )  //Output phase error
    );
    

    
    //Gardner bits are synchronized and sampled for judgment, and the two signals after the judgment are outputted
    gardner_sync gardner_sync_inst
    (
        .clk            (clk_500k           ),  //500kHz
        .rst_n          (rst_n              ),
        .data_in_I      (filtered_I[42:28]  ),  //Truncation and loading of truncated data into Gardner Bit Synchronization Module
        .data_in_Q      (filtered_Q[42:28]  ),

        .sync_out_I     (sync_I             ),
        .sync_out_Q     (sync_Q             ),
        .sync_flag      (sync_flag          )   //Best Sampling Judgment Moment Markers
    );
    
    //Merge IQ two ways
    iq_comb 
    #(.SAMPLE(100))   //Number of samples per code element
    iq_comb_inst
    (
        .clk            (clk_500k   ),
        .rst_n          (rst_n      ),
        .sync_I         (sync_I     ),
        .sync_Q         (sync_Q     ),
        .sync_flag_i    (sync_flag  ),  //Synchronization flag input from Gardner bit synchronizer
                         
        .demo_ser_o     (demo_ser_o ),
        .sync_flag_o    (sync_flag_d1)   //Synchronized output data to subsequent modules
    );

    //Data validity check and output of the final parallel 40bit result
    data_valid 
    #(.HEADER(HEADER))  //header
    data_valid_inst
    (
        .clk            (clk_500k       ),  //500KHz
        .rst_n          (rst_n          ),
        //.ser_i          (demo_ser_o     ),  //Serial data input from iq_comb module
        .ser_i          (demo_ser_o     ),  //Serial data input from iq_comb module
        .sync_flag      (sync_flag_d1   ),  //synchronization flag

        .header_flag    (header_flag    ),  //Correct frame header detected
        .valid_flag     (valid_flag     ),  //The header and checksum are correct flags for valid data.
        .valid_data_o   (para_out       )   //Parallel output of valid data
    );
    
    
    

    
endmodule
