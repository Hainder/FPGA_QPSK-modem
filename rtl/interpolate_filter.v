//Interpolation filters, which calculate interpolation values based on the input data, using the Farrow structure of the interpolation filters.
module interpolate_filter
(
    input wire          clk         ,
    input wire          rst_n       ,
    input wire  [14:0]  data_in_I   ,
    input wire  [14:0]  data_in_Q   ,
    input wire  [15:0]  uk          ,   //Decimal spacing, 15bit decimal places

    output wire [19:0]  I_y         ,   //I-interpolated outputs
    output wire [19:0]  Q_y             //Q-way interpolation output
);

    reg [14:0]          data_in_I_d1;  //Input data delayed by one clock
    reg [14:0]          data_in_I_d2;  //Input data delayed by two clocks
    reg [14:0]          data_in_I_d3;  //Input data delayed by three clocks    
    
    
    reg [14:0]          data_in_Q_d1;  //Input data delayed by one clock
    reg [14:0]          data_in_Q_d2;  //Input data delayed by two clocks
    reg [14:0]          data_in_Q_d3;  //Input data delayed by three clocks    
    
    reg [19:0]          I_y_temp    ;  //I-way interpolation outputs temporary variables
    reg [19:0]          Q_y_temp    ;  //Q-way interpolation outputs temporary variables
    
    
    
    //Intermediate data for the Farrow structural interpolation filter
    //The maximum value range is three times the input data, so the design is two bits wider than the input data bit width.
    //The actual bit width used does not amount to more than two bits.
    reg [16:0]          f1_I        ; 
    reg [16:0]          f2_I        ;
    reg [16:0]          f3_I        ;

    reg [16:0]          f1_Q        ; 
    reg [16:0]          f2_Q        ;
    reg [16:0]          f3_Q        ;
    
    // f1 = 0.5x(m)−0.5x(m−1)−0.5x(m−2)+0.5x(m−3)
    // f2 = −0.5x(m)+1.5x(m−1)−0.5x(m−2)−0.5x(m−3)
    // f3 = x(m−2)
    // y(k) = f1*(μk)^2 + f2*uk + f3
    
    
    //Multiplier output result
    wire [32:0] mult_result_f1_1_I      ;  //The result of the first multiplier engaged by f1 to compute the I-way data
    wire [32:0] mult_result_f1_2_I      ;  //The result of the second multiplier engaged by f1 to compute the I-way data
    wire [32:0] mult_result_f2_1_I      ;  //The result of the first multiplier engaged by f2 to compute the I-way data

    wire [32:0] mult_result_f1_1_Q      ;  //The result of the first multiplier engaged by f1 to compute the Q-way data
    wire [32:0] mult_result_f1_2_Q      ;  //The result of the second multiplier engaged by f1 to compute the Q-way data
    wire [32:0] mult_result_f2_1_Q      ;  //The result of the first multiplier engaged by f2 to compute the Q-way data
    
    
    //Tap on input data as well as intermediate variables
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            data_in_I_d1 <= 15'b0;
            data_in_I_d2 <= 15'b0;
            data_in_I_d3 <= 15'b0;
            data_in_Q_d1 <= 15'b0;
            data_in_Q_d2 <= 15'b0;
            data_in_Q_d3 <= 15'b0;
        end else begin
            data_in_I_d1 <= data_in_I;
            data_in_I_d2 <= data_in_I_d1;
            data_in_I_d3 <= data_in_I_d2;
            data_in_Q_d1 <= data_in_Q;
            data_in_Q_d2 <= data_in_Q_d1;
            data_in_Q_d3 <= data_in_Q_d2;
        end
    end
    
    //Calculate f1, f2, f3
    // f1 = 0.5x(m)−0.5x(m−1)−0.5x(m−2)+0.5x(m−3)
    // f2 = −0.5x(m)+1.5x(m−1)−0.5x(m−2)−0.5x(m−3)
    // f3 = x(m−2)
    // Multiplication by shifting
    always @ (*) begin
        f1_I = {{3{data_in_I[14]}}, data_in_I[14:1]} - {{3{data_in_I_d1[14]}}, data_in_I_d1[14:1]} - {{3{data_in_I_d2[14]}}, data_in_I_d2[14:1]} + {{3{data_in_I_d3[14]}}, data_in_I_d3[14:1]};
        f2_I = {{2{data_in_I_d1[14]}}, data_in_I_d1} + {{3{data_in_I_d1[14]}}, data_in_I_d1[14:1]} - {{3{data_in_I[14]}}, data_in_I[14:1]} - {{3{data_in_I_d2[14]}}, data_in_I_d2[14:1]} - {{3{data_in_I_d3[14]}}, data_in_I_d3[14:1]};
        f3_I = {{2{data_in_I_d2[14]}}, data_in_I_d2};
        
        f1_Q = {{3{data_in_Q[14]}}, data_in_Q[14:1]} - {{3{data_in_Q_d1[14]}}, data_in_Q_d1[14:1]} - {{3{data_in_Q_d2[14]}}, data_in_Q_d2[14:1]} + {{3{data_in_Q_d3[14]}}, data_in_Q_d3[14:1]};
        f2_Q = {{2{data_in_Q_d1[14]}}, data_in_Q_d1} + {{3{data_in_Q_d1[14]}}, data_in_Q_d1[14:1]} - {{3{data_in_Q[14]}}, data_in_Q[14:1]} - {{3{data_in_Q_d2[14]}}, data_in_Q_d2[14:1]} - {{3{data_in_Q_d3[14]}}, data_in_Q_d3[14:1]};
        f3_Q = {{2{data_in_Q_d2[14]}}, data_in_Q_d2};
    end
    
    
    //I-way multiplication calculations

    // y(k) = f1*(μk)^2 + f2*uk + f3
    //The first multiplier engaged by f1 to compute the I-way data
    mult_interploate  mult_interploate_f1_1_I(
        .CLK(clk),  // input wire CLK
        .A(f1_I),      // input wire [16 : 0] A
        .B(uk),      // input wire [15 : 0] B
        .P(mult_result_f1_1_I)      // output wire [32 : 0] P
    );
    
    //The first multiplier engaged by f1 to compute the I-way data
    //Since the lower 15 bits of the definition uk represent decimal places, 
        //the multiplier does not associate them with decimals in its calculations, considering them to be ordinary binary numbers
    //So here mult_result_f1_1_I is shifted 15 bits to the right and multiplied by uk
    mult_interploate  mult_interploate_f1_2_I(
        .CLK(clk),  
        .A(mult_result_f1_1_I[31:15]), 
        .B(uk),      
        .P(mult_result_f1_2_I)      
    );  
    
    //The first multiplier engaged by f2 calculates the I-way data    
    mult_interploate  mult_interploate_f2_1_I(
        .CLK(clk),  
        .A(f2_I),      
        .B(uk),      
        .P(mult_result_f2_1_I)
    );  
    
    
    
    //Q-way multiplication calculation
    

    //The first multiplier engaged by f1 to compute the Q-way data
    mult_interploate  mult_interploate_f1_1_Q(
        .CLK(clk),  
        .A(f1_Q),      
        .B(uk),      
        .P(mult_result_f1_1_Q)  
    );
    
    //The first multiplier engaged by f1 to compute the Q-way data
    //Since the lower 15 bits of the definition uk represent decimal places, 
        //the multiplier does not associate them with decimals in its calculations, considering them to be ordinary binary numbers
    //So here mult_result_f1_1_Q is shifted 15 bits to the right and multiplied by uk
    mult_interploate  mult_interploate_f1_2_Q(
        .CLK(clk),  
        .A(mult_result_f1_1_Q[31:15]),  
        .B(uk),      
        .P(mult_result_f1_2_Q)      
    );  
    
    //The first multiplier engaged by f2 to compute the Q-way data    
    mult_interploate  mult_interploate_f2_1_Q(
        .CLK(clk),  
        .A(f2_Q),   
        .B(uk),      
        .P(mult_result_f2_1_Q)  
    );  
    
    
    //Interpolation filter output data I_y I_Q
    //At this point the output interpolated data has been synchronized with the local clock clk
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            I_y_temp <= 20'b0;
            Q_y_temp <= 20'b0;
        end else begin
            I_y_temp <= {{2{mult_result_f1_2_I[32]}}, mult_result_f1_2_I[32:15]} + {{2{mult_result_f2_1_I[32]}}, mult_result_f2_1_I[32:15]} + {{3{f3_I[16]}}, f3_I};
            Q_y_temp <= {{2{mult_result_f1_2_Q[32]}}, mult_result_f1_2_Q[32:15]} + {{2{mult_result_f2_1_Q[32]}}, mult_result_f2_1_Q[32:15]} + {{3{f3_Q[16]}}, f3_Q};
        end
    end
    
    assign I_y = I_y_temp;
    assign Q_y = Q_y_temp;
    
    
    



endmodule 