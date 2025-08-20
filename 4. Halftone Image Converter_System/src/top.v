`include "../src/error_diffusion.v"
`include "../src/grayscale.v"
module top(
    input               clk,
    input               rst_n,		
    output reg          gray_done,
    output reg          diff_done,

    output reg          rom_en,
    output reg  [17:0]  rom_addr,
    input       [23:0]  rom_data,

    output reg          ram_ren,
    output reg          ram_wen,
    output reg  [17:0]  ram_addr,
    output reg  [7:0]   ram_idata,
    input       [7:0]   ram_odata
);


  localparam IDLE               = 4'b0000;  
  localparam GRAYSCALE_CONVERT  = 4'b0001; 

  // Error Diffusion - Read neighboring pixels
  localparam READ_CENTER_PIXEL  = 4'b0100; 
  localparam READ_RIGHT_PIXEL   = 4'b0101;  
  localparam READ_BOTTOM_RIGHT  = 4'b0110;   
  localparam READ_BOTTOM_CENTER = 4'b0111;  
  localparam READ_BOTTOM_LEFT   = 4'b1000;  

  // Error Diffusion - Write diffused pixels
  localparam WRITE_CENTER_PIXEL = 4'b1001;  
  localparam WRITE_RIGHT_PIXEL  = 4'b1010;  
  localparam WRITE_BOTTOM_RIGHT = 4'b1011;  
  localparam WRITE_BOTTOM_CENTER= 4'b1100;  
  localparam WRITE_BOTTOM_LEFT  = 4'b1101;  

// Internal Registers
  reg [ 3:0] state;
  reg [17:0] pixel_cnt;
  reg        valid_i;
  reg [ 2:0] mux_sel;

// Internal Wires
  wire [7:0] gray_o;
  wire [7:0] diff_o [0:4];
  wire       done;
  reg  [7:0] mux_out;  

// 8-to-1 MUX for RAM input data selection
  always @(*) begin
    case(mux_sel)
      3'd0: mux_out = gray_o;      
      3'd1: mux_out = diff_o[0];   
      3'd2: mux_out = diff_o[1];   
      3'd3: mux_out = diff_o[2];   
      3'd4: mux_out = diff_o[3];   
      3'd5: mux_out = diff_o[4];   
      3'd6: mux_out = 8'd0;        
      3'd7: mux_out = 8'd0;        
      default: mux_out = 8'd0;
    endcase
  end

// Instantiating
  grayscale gray_inst(
  .clk(clk),
  .rst_n(rst_n),
  .mode(2'b10),  
  .color(rom_data),
  .gray(gray_o)
  );

  error_diffusion diff_inst(
  .clk(clk),
  .rst_n(rst_n),
  .valid_i(valid_i),
  .data_i(ram_odata),
  .result0(diff_o[0]),
  .result1(diff_o[1]),
  .result2(diff_o[2]),
  .result3(diff_o[3]),
  .result4(diff_o[4]),
  .done(done)
);

// FSM
// State logic
  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)   state <= IDLE;
    else begin
      case(state)
        IDLE:               state <= GRAYSCALE_CONVERT;
        GRAYSCALE_CONVERT:  state <= gray_done ? READ_CENTER_PIXEL : GRAYSCALE_CONVERT;

        READ_CENTER_PIXEL:  state <= READ_RIGHT_PIXEL;     
        READ_RIGHT_PIXEL:   state <= READ_BOTTOM_RIGHT;    
        READ_BOTTOM_RIGHT:  state <= READ_BOTTOM_CENTER;   
        READ_BOTTOM_CENTER: state <= READ_BOTTOM_LEFT;     
        READ_BOTTOM_LEFT:   state <= WRITE_CENTER_PIXEL;   

        WRITE_CENTER_PIXEL: state <= WRITE_RIGHT_PIXEL;    
        WRITE_RIGHT_PIXEL:  state <= WRITE_BOTTOM_RIGHT;   
        WRITE_BOTTOM_RIGHT: state <= WRITE_BOTTOM_CENTER;  
        WRITE_BOTTOM_CENTER:state <= WRITE_BOTTOM_LEFT;    
        WRITE_BOTTOM_LEFT:  state <= diff_done ? IDLE : READ_CENTER_PIXEL;  
        default:            state <= IDLE;
      endcase
    end
  end

// Control logic
  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n) begin
          pixel_cnt <= 18'd0;
          rom_addr  <= 18'd0;
          ram_addr  <= 18'd0;
          gray_done <= 1'b0;
          diff_done <= 1'b0;
    end else begin
      case(state)
        IDLE: begin
          pixel_cnt <= 18'd0;
          rom_addr  <= 18'd0;
          ram_addr  <= 18'd0;
          gray_done <= 1'b0;
          diff_done <= 1'b0;
        end
        GRAYSCALE_CONVERT: begin
          pixel_cnt <= gray_done ? 18'd0 : rom_addr;
          rom_addr  <= gray_done ? 18'd0 : rom_addr + 1;
          ram_addr  <= gray_done ? 18'd0 : pixel_cnt;
          gray_done <= ram_addr == 18'd262143;
        end
        READ_CENTER_PIXEL: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 1;
        end
        READ_RIGHT_PIXEL: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd513;
        end
        READ_BOTTOM_RIGHT: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd512;
        end
        READ_BOTTOM_CENTER: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd511;
        end
        READ_BOTTOM_LEFT: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt;
        end
        WRITE_CENTER_PIXEL: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 1;
        end
        WRITE_RIGHT_PIXEL: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd513;
        end
        WRITE_BOTTOM_RIGHT: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd512;
        end
        WRITE_BOTTOM_CENTER: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd511;
        end
        WRITE_BOTTOM_LEFT: begin
          pixel_cnt <= pixel_cnt + 1;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 1;
          diff_done <= pixel_cnt == 18'd262143;
        end
        default: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= rom_addr;
          ram_addr  <= ram_addr;
          gray_done <= gray_done;
          diff_done <= diff_done;
        end
      endcase
    end
  end

  always @(*) begin
    case(state)
      IDLE: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = 1'b0;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd0;
      end
      GRAYSCALE_CONVERT: begin
        rom_en    = 1'b1;
        ram_ren   = 1'b0;
        ram_wen   = 1'b1;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd0;  // Select grayscale output
      end
      READ_CENTER_PIXEL: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b1;
        ram_wen   = 1'b0;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd0;
      end
      READ_RIGHT_PIXEL: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[8:0] != 9'd511);
        ram_wen   = 1'b0;
        ram_idata = mux_out;
        valid_i   = 1'b1;
        mux_sel   = 3'd0;
      end
      READ_BOTTOM_RIGHT: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[8:0] != 9'd511) && (pixel_cnt[17:9] != 9'd511);
        ram_wen   = 1'b0;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd0;
      end
      READ_BOTTOM_CENTER: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[17:9] != 9'd511);
        ram_wen   = 1'b0;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd0;
      end
      READ_BOTTOM_LEFT: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[17:9] != 9'd511) && (pixel_cnt[8:0] != 9'd0);
        ram_wen   = 1'b0;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd0;
      end
      WRITE_CENTER_PIXEL: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = 1'b1;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd1;  // Select diff_o[0]
      end
      WRITE_RIGHT_PIXEL: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[8:0] != 9'd511);
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd2;  // Select diff_o[1]
      end
      WRITE_BOTTOM_RIGHT: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[8:0] != 9'd511) && (pixel_cnt[17:9] != 9'd511);
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd3;  // Select diff_o[2]
      end
      WRITE_BOTTOM_CENTER: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[17:9] != 9'd511);
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd4;  // Select diff_o[3]
      end
      WRITE_BOTTOM_LEFT: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[17:9] != 9'd511) && (pixel_cnt[8:0] != 9'd0);
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd5;  // Select diff_o[4]
      end
      default: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = 1'b0;
        ram_idata = mux_out;
        valid_i   = 1'b0;
        mux_sel   = 3'd0;
      end
    endcase
  end


endmodule


