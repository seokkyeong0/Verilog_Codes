`timescale 1ns / 1ps

// Truth Table
// a | b | carry_in | sum | carry_out
// 0   0      0        0        0
// 0   1      0        1        0
// 1   0      0        1        0
// 1   1      0        0        1
// 0   0      1        1        0
// 0   1      1        0        1
// 1   0      1        0        1
// 1   1      1        1        1

// 2 XOR, 2 AND, 1 OR Gates
// or 2 Half Adder, 1 OR Gate

module full_adder(
    input  logic a          ,
    input  logic b          ,
    input  logic carry_in   ,
    output logic sum        ,
    output logic carry_out
    );

    assign sum = a ^ b ^ carry_in;
    assign carry_out = (a & b) | (carry_in & (a ^ b));
endmodule

//module full_adder_HA(
//    input  logic a          ,
//    input  logic b          ,
//    input  logic carry_in   ,
//    output logic sum        ,
//    output logic carry_out    
//    );
//
//    wire w_sum;
//    wire c0, c1;
//
//    half_adder U_HA_1(
//        .a     (a),
//        .b     (b),
//        .sum   (w_sum),
//        .carry (c0)
//    );
//
//    half_adder U_HA_2(
//        .a     (w_sum),
//        .b     (carry_in),
//        .sum   (sum),
//        .carry (c1)
//    );
//
//    assign carry_out = c0 | c1;
//endmodule
//
//module half_adder(
//    input  logic a     ,
//    input  logic b     ,
//    output logic sum   ,
//    output logic carry 
//    );
//
//    assign sum = a ^ b;
//    assign carry = a & b;
//endmodule
