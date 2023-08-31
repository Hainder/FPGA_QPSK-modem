`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.08.2023 10:05:29
// Design Name: 
// Module Name: dds_sin_fixer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dds_fixer(
    input [7:0] carry,
    output [7:0] carry_fixed
    );

    assign carry_fixed = carry < 8'd127 ? (carry+8'd127) :  (carry-8'd127);

endmodule
