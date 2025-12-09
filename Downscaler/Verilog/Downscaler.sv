module Downscaler #(
    parameter WIDTH   = 10,
    parameter HACT    = 10,
    parameter is_gray = 0,
    parameter ds_mode = 0
)(
    input  logic             clk,
    input  logic             rstn,
    input  logic             i_vsync,
    input  logic             i_hsync,
    input  logic             i_de,
    input  logic [WIDTH-1:0] i_r_data,
    input  logic [WIDTH-1:0] i_g_data,
    input  logic [WIDTH-1:0] i_b_data,
    output logic             o_vsync,
    output logic             o_hsync,
    output logic             o_de,
    output logic [WIDTH-1:0] o_r_data,
    output logic [WIDTH-1:0] o_g_data,
    output logic [WIDTH-1:0] o_b_data
);

    ///////////////////////////////
    // Wires
    ///////////////////////////////
    logic             o_vsync_gray;
    logic             o_hsync_gray;
    logic             o_de_gray;
    logic [WIDTH-1:0] o_r_data_gray;
    logic [WIDTH-1:0] o_g_data_gray;
    logic [WIDTH-1:0] o_b_data_gray;
    logic             o_vsync_bypass;
    logic             o_hsync_bypass;
    logic             o_de_bypass;
    logic [WIDTH-1:0] o_r_data_bypass;
    logic [WIDTH-1:0] o_g_data_bypass;
    logic [WIDTH-1:0] o_b_data_bypass;
    logic             o_vsync_sampling;
    logic             o_hsync_sampling;
    logic             o_de_sampling;
    logic [WIDTH-1:0] o_r_data_sampling;
    logic [WIDTH-1:0] o_g_data_sampling;
    logic [WIDTH-1:0] o_b_data_sampling;
    logic             o_vsync_average;
    logic             o_hsync_average;
    logic             o_de_average;
    logic [WIDTH-1:0] o_r_data_average;
    logic [WIDTH-1:0] o_g_data_average;
    logic [WIDTH-1:0] o_b_data_average;
    logic             o_vsync_average_3x3;
    logic             o_hsync_average_3x3;
    logic             o_de_average_3x3;
    logic [WIDTH-1:0] o_r_data_average_3x3;
    logic [WIDTH-1:0] o_g_data_average_3x3;
    logic [WIDTH-1:0] o_b_data_average_3x3;
    logic             o_vsync_cross;
    logic             o_hsync_cross;
    logic             o_de_cross;
    logic [WIDTH-1:0] o_r_data_cross;
    logic [WIDTH-1:0] o_g_data_cross;
    logic [WIDTH-1:0] o_b_data_cross;

    /////////////////////////////////////
    // Downscale Mode List (No-padding)
    // ds_mode = 0 : Bypass
    // ds_mode = 1 : 1/2 Sub-Sampling
    // ds_mode = 2 : 1/3 Sub-Sampling
    // ds_mode = 3 : 1/2 Average
    // ds_mode = 4 : 1/3 Average
    // ds_mode = 5 : 1/3 Cross
    /////////////////////////////////////

    // Gray Scale Output //
    DS_Gray #(
        .WIDTH(WIDTH)
    ) U_DS_Gray (
        .clk(clk),
        .rstn(rstn),
        .i_vsync(i_vsync),
        .i_hsync(i_hsync),
        .i_de(i_de),
        .i_r_data(i_r_data),
        .i_g_data(i_g_data),
        .i_b_data(i_b_data),
        .o_vsync(o_vsync_gray),
        .o_hsync(o_hsync_gray),
        .o_de(o_de_gray),
        .o_r_data(o_r_data_gray),
        .o_g_data(o_g_data_gray),
        .o_b_data(o_b_data_gray)
    );

    // Gray or RGB Input
    logic [WIDTH-1:0] i_r;
    logic [WIDTH-1:0] i_g;
    logic [WIDTH-1:0] i_b;
    assign i_r = (is_gray) ? o_r_data_gray : i_r_data;
    assign i_g = (is_gray) ? o_g_data_gray : i_g_data;
    assign i_b = (is_gray) ? o_b_data_gray : i_b_data;

    // Bypass Mode //
    DS_Bypass #(
        .WIDTH(WIDTH)
    ) U_DS_Bypass (
        .clk(clk),
        .rstn(rstn),
        .i_vsync(i_vsync),
        .i_hsync(i_hsync),
        .i_de(i_de),
        .i_r_data(i_r),
        .i_g_data(i_g),
        .i_b_data(i_b),
        .o_vsync(o_vsync_bypass),
        .o_hsync(o_hsync_bypass),
        .o_de(o_de_bypass),
        .o_r_data(o_r_data_bypass),
        .o_g_data(o_g_data_bypass),
        .o_b_data(o_b_data_bypass)
    );

    // 1/2 & 1/3 Sub-Sampling Mode //
    DS_Sampling #(
        .WIDTH(WIDTH),
        .HACT(HACT),
        .SAMPLING(ds_mode)
    ) U_DS_Sampling (
        .clk(clk),
        .rstn(rstn),
        .i_vsync(i_vsync),
        .i_hsync(i_hsync),
        .i_de(i_de),
        .i_r_data(i_r),
        .i_g_data(i_g),
        .i_b_data(i_b),
        .o_vsync(o_vsync_sampling),
        .o_hsync(o_hsync_sampling),
        .o_de(o_de_sampling),
        .o_r_data(o_r_data_sampling),
        .o_g_data(o_g_data_sampling),
        .o_b_data(o_b_data_sampling)
    );

    // 1/2 Average Mode //
    DS_Average #(
        .WIDTH(WIDTH),
        .HACT(HACT)
    ) U_DS_Average (
        .clk(clk),
        .rstn(rstn),
        .i_vsync(i_vsync),
        .i_hsync(i_hsync),
        .i_de(i_de),
        .i_r_data(i_r),
        .i_g_data(i_g),
        .i_b_data(i_b),
        .o_vsync(o_vsync_average),
        .o_hsync(o_hsync_average),
        .o_de(o_de_average),
        .o_r_data(o_r_data_average),
        .o_g_data(o_g_data_average),
        .o_b_data(o_b_data_average)
    );

    // 1/3 Average Mode //
    DS_Average_3x3 #(
        .WIDTH(WIDTH),
        .HACT(HACT)
    ) U_DS_Average_3x3 (
        .clk(clk),
        .rstn(rstn),
        .i_vsync(i_vsync),
        .i_hsync(i_hsync),
        .i_de(i_de),
        .i_r_data(i_r),
        .i_g_data(i_g),
        .i_b_data(i_b),
        .o_vsync(o_vsync_average_3x3),
        .o_hsync(o_hsync_average_3x3),
        .o_de(o_de_average_3x3),
        .o_r_data(o_r_data_average_3x3),
        .o_g_data(o_g_data_average_3x3),
        .o_b_data(o_b_data_average_3x3)
    );

    // 1/3 Cross Mode //
    DS_Cross #(
        .WIDTH(WIDTH),
        .HACT(HACT)
    ) U_DS_Cross (
        .clk(clk),
        .rstn(rstn),
        .i_vsync(i_vsync),
        .i_hsync(i_hsync),
        .i_de(i_de),
        .i_r_data(i_r),
        .i_g_data(i_g),
        .i_b_data(i_b),
        .o_vsync(o_vsync_cross),
        .o_hsync(o_hsync_cross),
        .o_de(o_de_cross),
        .o_r_data(o_r_data_cross),
        .o_g_data(o_g_data_cross),
        .o_b_data(o_b_data_cross)
    );

    // Final Output //
    assign o_vsync  = (ds_mode == 0) ? o_vsync_bypass  : ((ds_mode == 1 || ds_mode == 2) ? o_vsync_sampling  : ((ds_mode == 3) ? o_vsync_average  : ((ds_mode == 4) ? o_vsync_average_3x3  : ((ds_mode == 5) ? o_vsync_cross  : 'd0)))); 
    assign o_hsync  = (ds_mode == 0) ? o_hsync_bypass  : ((ds_mode == 1 || ds_mode == 2) ? o_hsync_sampling  : ((ds_mode == 3) ? o_hsync_average  : ((ds_mode == 4) ? o_hsync_average_3x3  : ((ds_mode == 5) ? o_hsync_cross  : 'd0))));
    assign o_de     = (ds_mode == 0) ? o_de_bypass     : ((ds_mode == 1 || ds_mode == 2) ? o_de_sampling     : ((ds_mode == 3) ? o_de_average     : ((ds_mode == 4) ? o_de_average_3x3     : ((ds_mode == 5) ? o_de_cross     : 'd0))));
    assign o_r_data = (ds_mode == 0) ? o_r_data_bypass : ((ds_mode == 1 || ds_mode == 2) ? o_r_data_sampling : ((ds_mode == 3) ? o_r_data_average : ((ds_mode == 4) ? o_r_data_average_3x3 : ((ds_mode == 5) ? o_r_data_cross : 'd0))));
    assign o_g_data = (ds_mode == 0) ? o_g_data_bypass : ((ds_mode == 1 || ds_mode == 2) ? o_g_data_sampling : ((ds_mode == 3) ? o_g_data_average : ((ds_mode == 4) ? o_g_data_average_3x3 : ((ds_mode == 5) ? o_g_data_cross : 'd0))));
    assign o_b_data = (ds_mode == 0) ? o_b_data_bypass : ((ds_mode == 1 || ds_mode == 2) ? o_b_data_sampling : ((ds_mode == 3) ? o_b_data_average : ((ds_mode == 4) ? o_b_data_average_3x3 : ((ds_mode == 5) ? o_b_data_cross : 'd0))));
    
endmodule