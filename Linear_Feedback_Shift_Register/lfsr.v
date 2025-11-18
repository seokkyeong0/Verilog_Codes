`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/06 23:01:54
// Design Name: 
// Module Name: lfsr
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


module lfsr(
    input            clk    ,
    input            rst    ,
    input            enb    ,
    input            load   ,
    input      [7:0] seed   ,
    output reg [7:0] rand   
    );

    // feedback network wire
    wire feedback;

    // 8-bit LFSR polynomial x^8 + x^6 + x^5 + x^4 + 1
    assign feedback = rand[7] ^ rand[5] ^ rand[4] ^ rand[3];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            // non-zero default seed
            rand <= 8'h01;
        end else if(load) begin
            rand <= seed;
        end else if(enb) begin
            // shift left and append feedback into LSB
            rand <= {rand[6:0], feedback};
            // alternative: shift right with q <= {feedback, q[7:1]};
        end
    end
endmodule
