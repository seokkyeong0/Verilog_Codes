module DS_Sampling #(
    parameter WIDTH    = 10,
    parameter HACT     = 10,
    parameter SAMPLING = 2
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

    // Edge Detector (Polarity Control) //
    logic v_sync, h_sync, d_sync;

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            v_sync   <= 1'b0;
            h_sync   <= 1'b0;
            d_sync   <= 1'b0;
        end else begin
            v_sync   <= i_vsync;
            h_sync   <= i_hsync;   
            d_sync   <= i_de;
        end
    end

  	logic v_r, v_f, h_r, h_f, d_r, d_f;
    assign v_r = ~v_sync & i_vsync; // rising edge  (vsync)
    assign v_f = v_sync & ~i_vsync; // falling edge (vsync)
    assign h_r = ~h_sync & i_hsync; // rising edge  (hsync)
    assign h_f = h_sync & ~i_hsync; // falling edge (hsync)
    assign d_r = ~d_sync & i_de;    // rising edge  (de)
    assign d_f = d_sync & ~i_de;    // falling edge (de)

    // Horizontal & Output Toggle Counters //
    logic [$clog2(HACT)-1:0] h_cnt;
    logic [$clog2(HACT)-1:0] p_cnt;

    // Sequential Logic //
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            h_cnt <= 0;
            p_cnt <= 0;
        end else begin
            if (h_r) p_cnt <= 0;
            if (v_r) h_cnt <= 0;
            if (d_f) h_cnt <= h_cnt + 1;
            if (i_de) p_cnt <= p_cnt + 1;
        end
    end
  
  	logic output_valid;
    assign output_valid = (SAMPLING == 2) ? (h_cnt % 2 == 0 && p_cnt % 2 == 0) : (h_cnt % 3 == 0 && p_cnt % 3 == 0);

    // Output //
    assign o_vsync  = i_vsync;
    assign o_hsync  = i_hsync;
    assign o_de     = output_valid ? i_de : 1'b0;
    assign o_r_data = output_valid ? i_r_data : 'd0;
  	assign o_g_data = output_valid ? i_g_data : 'd0;
  	assign o_b_data = output_valid ? i_b_data : 'd0;

endmodule