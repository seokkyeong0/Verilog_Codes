`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/25 10:47:34
// Design Name: 
// Module Name: tb_BMP_IMG
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

`include "CBMP.sv"

//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////////                                                                     /////////
////////                            Testbench TOP                            /////////
////////                                                                     /////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////


module tb_BMP_Filter ();

    logic clk;
    logic reset;
    logic h_sync;
    logic v_sync;
    logic DE;

    logic                 [9:0] x_pixel;
    logic                 [9:0] y_pixel;
    logic                [23:0] imgData;
    logic [$clog2(640*480)-1:0] addr;
    logic                 [7:0] r_port;
    logic                 [7:0] g_port;
    logic                 [7:0] b_port;

    always #5 clk = ~clk;

    imgRom U_imgROM(
        .clk(clk),
        .addr(addr),
        .data(imgData)
    );

    VGA_Syncher U_VGA_Syncher(
        .clk(clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    ImgReader U_ImgReader(
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .img(imgData),
        .addr(addr),
        .r_port(r_port),
        .g_port(g_port),
        .b_port(b_port)
    );

    // User Logics //

    // Add Filters //

    /////////////////
    

    // BMP Monitor
    monitor_bmp U_monitor_bmp(
        .clk(clk),
        .reset(reset),
        .v_sync(v_sync),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .r_port(r_port),
        .g_port(g_port),
        .b_port(b_port)
    );

    initial begin
        #00; clk = 0; reset = 1;
        #10; reset = 0;

        @(posedge v_sync);
        $finish;
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////////                                                                     /////////
////////                            Filter Modules                           /////////
////////                                                                     /////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

// ...

//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////////                                                                     /////////
////////                             Core Modules                           /////////
////////                                                                     /////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

module VGA_Syncher(
    input  logic clk,
    input  logic reset,
    output logic h_sync,
    output logic v_sync,
    output logic DE,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel
);

    logic pclk;
    logic [9:0] h_counter, v_counter;

    pixel_counter U_Pixel_Counter(
        .clk(clk),
        .reset(reset),
        .h_counter(h_counter),
        .v_counter(v_counter)
    );

    vga_sync U_VGA_Sync(
        .h_counter(h_counter),
        .v_counter(v_counter),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );
    
endmodule

module pixel_counter (
    input  logic       clk,
    input  logic       reset,
    output logic [9:0] h_counter,
    output logic [9:0] v_counter
);
    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge clk) begin
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end
endmodule

module vga_sync (
    input  logic [9:0] h_counter,
    input  logic [9:0] v_counter,
    output logic       h_sync,
    output logic       v_sync,
    output logic       DE,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel
);

    // VGA Signal 640 * 480 @ 60Hz
    localparam H_Visible_area = 640;	
    localparam H_Front_porch  = 16;	
    localparam H_Sync_pulse	  = 96;	
    localparam H_Back_porch	  = 48;	

    localparam V_Visible_area = 480;
    localparam V_Front_porch  = 10;
    localparam V_Sync_pulse	  = 2;
    localparam V_Back_porch	  = 33;

    assign h_sync  = !((h_counter >= H_Visible_area + H_Front_porch) 
                     && (h_counter < H_Visible_area + H_Front_porch + H_Sync_pulse));
    assign v_sync  = !((v_counter >= V_Visible_area + V_Front_porch) 
                     && (v_counter < V_Visible_area + V_Front_porch + V_Sync_pulse));
    assign DE      = (h_counter  < H_Visible_area) && (v_counter < V_Visible_area);
    assign x_pixel = h_counter;
    assign y_pixel = v_counter;
endmodule

module ImgReader(
    input  logic                       DE,
    input  logic                 [9:0] x_pixel,
    input  logic                 [9:0] y_pixel,
    input  logic                [23:0] img,
    output logic [$clog2(640*480)-1:0] addr,
    output logic                 [7:0] r_port,
    output logic                 [7:0] g_port,
    output logic                 [7:0] b_port
);

    assign addr = DE ? (640 * y_pixel + x_pixel) : 'bz;
    assign {r_port, g_port, b_port} = DE ? {img[23:16], img[15:8], img[7:0]} : 'b0;
endmodule

module imgRom (
    input  logic                       clk,
    input  logic [$clog2(640*480)-1:0] addr,
    output logic [               23:0] data
);
    byte mem [640*480*3];

    CBMP src;

    initial begin
        src = new("src_640x480x3.bmp", "rb");
        src.read();
        mem = src.bmpImgData;
        src.close();
    end

    always_ff @(posedge clk) begin
        data[7:0]   <= mem[addr*3+0];
        data[15:8]  <= mem[addr*3+1];
        data[23:16] <= mem[addr*3+2];
    end
endmodule

module monitor_bmp (
  input logic       clk,
  input logic       reset,
  input logic       v_sync,
  input logic [9:0] x_pixel,
  input logic [9:0] y_pixel,
  input logic [7:0] r_port,
  input logic [7:0] g_port,
  input logic [7:0] b_port
);

  byte mem[640*480*3];

  always_ff @(posedge clk) begin
    mem[(640 * y_pixel + x_pixel) * 3 + 2] <= r_port;
    mem[(640 * y_pixel + x_pixel) * 3 + 1] <= g_port;
    mem[(640 * y_pixel + x_pixel) * 3 + 0] <= b_port;
  end

  CBMP headerSrc;
  CBMP target;

  initial begin
    #10;
    headerSrc = new("src_640x480x3.bmp", "rb");
    target    = new("target_640x480x3.bmp", "wb");
    headerSrc.read();
    @(negedge v_sync);
    target.write(headerSrc.bmpHeader, $size(headerSrc.bmpHeader));
    target.write(mem, $size(mem));
    headerSrc.close();
    target.close();
  end
endmodule