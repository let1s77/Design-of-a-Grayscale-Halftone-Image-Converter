module error_diffusion(
  input            clk,
  input            rst_n,
  input            valid_i,
  input      [7:0] data_i,

  output reg [7:0] result0,  // Center pixel (quantized)
  output reg [7:0] result1,  // Right pixel (with 7/16 error)
  output reg [7:0] result2,  // Lower right pixel (with 1/16 error)
  output reg [7:0] result3,  // Lower center pixel (with 5/16 error)
  output reg [7:0] result4,  // Lower left pixel (with 3/16 error)
  output reg       done
);


  localparam IDLE            = 3'b000;  
  localparam CENTER_PIXEL    = 3'b001; 
  localparam RIGHT_PIXEL     = 3'b010;  
  localparam LOWER_RIGHT     = 3'b011; 
  localparam LOWER_CENTER    = 3'b100;  
  localparam LOWER_LEFT      = 3'b101;  
  localparam DONE            = 3'b110;  


  reg  [ 2:0] state;
  reg  [11:0] data_r;        
  reg  [12:0] error;         
  reg  [12:0] result_r;      



  
  wire clip_to_zero = result_r[12] && error[12];
  wire clip_to_255  = (result_r[12] || (result_r[11:4] == 8'd255)) && !error[12];
  
  
  wire [7:0] integer_part   = result_r[11:4];                  
  wire       frac_half      = result_r[3];                       
  wire       frac_remainder = |result_r[2:0];                    
  wire       integer_lsb    = result_r[4];                       // LSB of integer (for even rounding)
  
  wire [7:0] rounded_result = integer_part + (frac_half && (frac_remainder || integer_lsb));
  
  wire [7:0] result_w = (clip_to_255) ? 8'd255 :
                        (clip_to_zero) ? 8'd0   : rounded_result;


// Floyd-Steinberg
  wire [12:0] error_1_16 = error;                                 
  wire [12:0] error_3_16 = error + (error << 1);                       
  wire [12:0] error_5_16 = error + (error << 2);                     
  wire [12:0] error_7_16 = error + (error << 1) + (error << 2);    


// FSM

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      state <= IDLE;
    else begin
      case (state)
        IDLE:         state <= valid_i ? CENTER_PIXEL : IDLE;
        CENTER_PIXEL: state <= RIGHT_PIXEL;
        RIGHT_PIXEL:  state <= LOWER_RIGHT; 
        LOWER_RIGHT:  state <= LOWER_CENTER; 
        LOWER_CENTER: state <= LOWER_LEFT; 
        LOWER_LEFT:   state <= DONE;
        DONE:         state <= IDLE;
        default:      state <= IDLE;
      endcase
    end
  end


  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      // Reset all registers
      data_r  <= 12'd0;
      error   <= 13'd0;
      result0 <= 8'd0;
      result1 <= 8'd0;
      result2 <= 8'd0;
      result3 <= 8'd0;
      result4 <= 8'd0;
      done    <= 1'b0;
    end 
    else begin
      case (state)
        
        IDLE: begin
          data_r   <= data_i;
          error    <= 13'd0;
          result_r <= 13'd0;
          done     <= 1'b0;
        end 
        
        CENTER_PIXEL: begin
          data_r   <= data_i;
          error    <= data_r[7] ? data_r - 8'd255 : data_r;  
          result_r <= data_r[7] ? 13'd4080 : 13'd0;
        end 
        
        RIGHT_PIXEL: begin
          data_r   <= data_i;
          result_r <= (data_r << 4) + error_7_16;           
          result0  <= result_w;                              
        end 
        
        LOWER_RIGHT: begin
          data_r   <= data_i;
          result_r <= (data_r << 4) + error_1_16;           // pixel + 1/16 * error
          result1  <= result_w;                              // Store right pixel result
        end 
        
        LOWER_CENTER: begin
          data_r   <= data_i;
          result_r <= (data_r << 4) + error_5_16;          
          result2  <= result_w;                              
        end 
        
        LOWER_LEFT: begin
          result_r <= (data_r << 4) + error_3_16;          
          result3  <= result_w;                              
        end 
        
        DONE: begin
          result4  <= result_w;                          
          done     <= 1'b1;
        end
        
        default: begin
          // Hold all values
          data_r  <= data_r;
          error   <= error;
          result0 <= result0;
          result1 <= result1;
          result2 <= result2;
          result3 <= result3;
          result4 <= result4;
          done    <= 1'b0;
        end 
      endcase
    end
  end
endmodule

