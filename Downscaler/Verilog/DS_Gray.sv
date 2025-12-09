module DS_Gray #(
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

    // Register //
    logic [WIDTH+1:0] gray_temp;

    // Gray Scaler //
    assign gray_temp = (75 * i_r_data + 147 * i_g_data + 29 * i_b_data) >> 8;

    // Output //
    assign o_vsync = i_vsync;
    assign o_hsync = i_hsync;
    assign o_de    = i_de;
    assign o_r_data = gray_temp[WIDTH+1:2];
    assign o_g_data = gray_temp[WIDTH+1:2];
    assign o_b_data = gray_temp[WIDTH+1:2];

endmodule