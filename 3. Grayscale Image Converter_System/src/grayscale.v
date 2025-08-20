module grayscale(
  input         clk,
  input         rst_n,
  input         [23:0] color, // [23:16] Blue, [15:8] Green, [7:0] Red
  input         [1:0]  mode,    // 00: round up, 01: round down, 10: round to even
  output reg    [7:0]  gray
);

  wire [7:0] red   = color[7:0];
  wire [7:0] green = color[15:8];
  wire [7:0] blue  = color[23:16];
  
  // 0.3125 = 5/16 = (4+1)/16 = red>>2 + red>>4
  // 0.5625 = 9/16 = (8+1)/16 = green>>1 + green>>4  
  // 0.125 = 2/16 = 1/8 = blue>>3
  

  
  //shift left by 4 bits for fraction part to create Q8.4 format
  wire [11:0] red_fixed_point   = {red, 4'b0};     // Q8.4 format: 8-bit integer + 4-bit fraction
  wire [11:0] green_fixed_point = {green, 4'b0};   // Q8.4 format: 8-bit integer + 4-bit fraction  
  wire [11:0] blue_fixed_point  = {blue, 4'b0};    // Q8.4 format: 8-bit integer + 4-bit fraction

  // fixed-point format multiplication (results in larger bit width)
  wire [15:0] mult_r = (red_fixed_point >> 2) + (red_fixed_point >> 4);     // red * 5/16 
  wire [15:0] mult_g = (green_fixed_point >> 1) + (green_fixed_point >> 4); // green * 9/16 
  wire [15:0] mult_b = blue_fixed_point >> 3;                               // blue * 2/16 
  
  
  wire [17:0] sum = mult_r + mult_g + mult_b;  // Increase width to prevent overflow
  
  // Extract integer and fractional parts from final result
  wire [7:0] integer_part = sum[11:4];      // Extract 8-bit integer: bits [11:4] 
  wire [3:0] fraction_part = sum[3:0];      // Extract 4-bit fraction: bits [3:0]
  
  // Debug output (will be optimized away in synthesis)
  // always @(*) begin
  //   if (color == 24'hFFFCFF) begin  // Debug specific problematic pixel
  //     $display("DEBUG: R=%h G=%h B=%h", red, green, blue);
  //     $display("DEBUG: mult_r=%h mult_g=%h mult_b=%h", mult_r, mult_g, mult_b);
  //     $display("DEBUG: sum=%h integer=%h fraction=%h", sum, integer_part, fraction_part);
  //     $display("DEBUG: mode=%b final_gray=%h", mode, gray);
  //   end
  // end
  
  // Rounding logic
  reg [7:0] gray_comb;
  
  always @(*) begin
    case (mode)
      2'b00: begin // Round up
        if (fraction_part > 4'd0)
          gray_comb = integer_part + 8'd1;
        else
          gray_comb = integer_part;
      end
      
      2'b01: begin // Round down 
        gray_comb = integer_part;
      end
      
      2'b10: begin // Round to even
        if (fraction_part > 4'd8) begin
          // Fraction > 0.5, round up
          gray_comb = integer_part + 8'd1;
        end else if (fraction_part < 4'd8) begin
          // Fraction < 0.5, round down
          gray_comb = integer_part;
        end else begin
          // Fraction = 0.5, round to nearest even
          if (integer_part[0] == 1'b0)
            gray_comb = integer_part;      // Already even
          else
            gray_comb = integer_part + 8'd1; // Make it even
        end
      end
      
      default: begin 
        gray_comb = integer_part;
      end
    endcase
  end

  // Add clock delay to sync with ROM output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gray <= 8'd0;
    end else begin
      gray <= gray_comb;
    end
  end

endmodule