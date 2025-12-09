module DS_Bypass #(
    parameter WIDTH = 10
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

    // Output (Conntected Directly)
    assign o_vsync  = i_vsync; 
    assign o_hsync  = i_hsync;
    assign o_de     = i_de;
    assign o_r_data = i_r_data;
    assign o_g_data = i_g_data;
    assign o_b_data = i_b_data;
    
endmodule