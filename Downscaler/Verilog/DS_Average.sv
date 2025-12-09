module DS_Average #(
    parameter WIDTH = 10,
    parameter HACT  = 10
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
    
    // Line Buffer for 2x2 window calculation //
    logic [(WIDTH*3)-1:0] line_buf [0:HACT-1];  // 1 line ago
    
    // Shift Register 2x2
    logic [(WIDTH*3)-1:0] sr [0:1][0:1];
    
    // Horizon & Pointer Counters //
    logic [$clog2(HACT)-1:0] h_cnt;
    logic [$clog2(HACT)-1:0] p_cnt;
    
    logic [(WIDTH*3)-1:0] current_pixel;
    assign current_pixel = {i_r_data, i_g_data, i_b_data};
    
    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            h_cnt <= 0;
            p_cnt <= 0;
            for(int i = 0; i < HACT; i++) begin
                line_buf[i] <= 'd0;
            end
            for(int i = 0; i < 2; i++) begin
                for(int j = 0; j < 2; j++) begin
                    sr[i][j] <= 'd0;
                end
            end
        end else begin
            if (v_r) h_cnt <= 0;
            if (d_f) h_cnt <= h_cnt + 1;
            
            if (i_de) begin
                // Shift Register Update
                // Row 0 (1 line ago)
                sr[0][0] <= sr[0][1];
                sr[0][1] <= line_buf[p_cnt];
                
                // Row 1 (current line)
                sr[1][0] <= sr[1][1];
                sr[1][1] <= current_pixel;
                
                // Line Buffer Update
                line_buf[p_cnt] <= current_pixel;
                
                // Pointer Update
                if (p_cnt == HACT - 1) p_cnt <= 0;
                else p_cnt <= p_cnt + 1;
            end
        end 
    end
    
    // 2x2 Window //
    logic [WIDTH-1:0] window_r [0:1][0:1];
    logic [WIDTH-1:0] window_g [0:1][0:1];
    logic [WIDTH-1:0] window_b [0:1][0:1];
    
    always_comb begin
        for (int i = 0; i < 2; i++) begin
            for (int j = 0; j < 2; j++) begin
                window_r[i][j] = sr[i][j][WIDTH*3-1:WIDTH*2];
                window_g[i][j] = sr[i][j][WIDTH*2-1:WIDTH];
                window_b[i][j] = sr[i][j][WIDTH-1:0];
            end
        end
    end
    
    // 2x2 Window Calculation //
    logic [$clog2(2**(WIDTH+2))-1:0] sum_r;
    logic [$clog2(2**(WIDTH+2))-1:0] sum_g;
    logic [$clog2(2**(WIDTH+2))-1:0] sum_b;
    
    logic output_valid;
  	assign output_valid = (p_cnt[0] == 1 && h_cnt[0] == 1);
    
    always_comb begin
        if (output_valid) begin
            sum_r = window_r[0][0] + window_r[0][1] + 
                    window_r[1][0] + window_r[1][1];
                    
            sum_g = window_g[0][0] + window_g[0][1] + 
                    window_g[1][0] + window_g[1][1];
                    
            sum_b = window_b[0][0] + window_b[0][1] + 
                    window_b[1][0] + window_b[1][1];
        end else begin
            sum_r = 'd0;
            sum_g = 'd0;
            sum_b = 'd0;
        end
    end
    
    // Output (sum >> 2 = sum / 4) //
    assign o_vsync  = i_vsync;
    assign o_hsync  = i_hsync;
    assign o_de     = output_valid ? i_de : 1'b0;
    assign o_r_data = output_valid ? sum_r[WIDTH+1:2] : 'd0;
    assign o_g_data = output_valid ? sum_g[WIDTH+1:2] : 'd0;
    assign o_b_data = output_valid ? sum_b[WIDTH+1:2] : 'd0;

endmodule