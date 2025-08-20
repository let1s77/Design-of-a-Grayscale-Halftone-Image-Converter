`include "../src/grayscale.v"
module top(
    input               clk,
    input               rst_n,		// negedge!
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

// State encoding
  localparam IDLE  = 4'b0000;
  localparam GRAY  = 4'b0001;

  localparam CP_R  = 4'b0100;
  localparam RP_R  = 4'b0101;
  localparam LRP_R = 4'b0110;
  localparam LCP_R = 4'b0111;
  localparam LLP_R = 4'b1000;

  localparam CP_W  = 4'b1001;
  localparam RP_W  = 4'b1010;
  localparam LRP_W = 4'b1011;
  localparam LCP_W = 4'b1100;
  localparam LLP_W = 4'b1101;

// Internal Registers
  reg [ 3:0] state;
  reg [17:0] pixel_cnt;
  reg        valid_i;

// Internal Wires
  wire [7:0] gray_o;
  wire [7:0] diff_o [0:4];
  wire       done;

// Instantiating
  grayscale gray_inst(
  .clk(clk),
  .rst_n(rst_n),
  .mode(2'b10),  // Try round down mode instead of round to even
  .color(rom_data),
  .gray(gray_o)
  );

  //error_diffusion diff_inst(
  //.clk(clk),
  //.rst_n(rst_n),
  //.valid_i(valid_i),
  //.data_i(ram_odata),
  //.result0(diff_o[0]),
  //.result1(diff_o[1]),
  //.result2(diff_o[2]),
  //.result3(diff_o[3]),
  //.result4(diff_o[4]),
  //.done(done)
//);

// FSM
// State logic
  always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)   state <= IDLE;
    else begin
      case(state)
        IDLE:    state <= GRAY;
        GRAY:    state <= gray_done ? CP_R : GRAY;

        CP_R:    state <= RP_R;                    // Read Center Pixel
        RP_R:    state <= LRP_R;                    // Read Right  Pixel
        LRP_R:   state <= LCP_R;                    // Read Low-R  Pixel
        LCP_R:   state <= LLP_R;                    // Read Low-C  Pixel
        LLP_R:   state <= CP_W;                     // Read Low-L  Pixel

        CP_W:    state <= RP_W;       // Write Center Pixel
        RP_W:    state <= LRP_W;                    // Write Right  Pixel
        LRP_W:   state <= LCP_W;                    // Write Low-R  Pixel
        LCP_W:   state <= LLP_W;                    // Write Low-C  Pixel
        LLP_W:   state <= CP_R;                     // Write Low_L  Pixel
        default: state <= IDLE;
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
        GRAY: begin
          pixel_cnt <= gray_done ? 18'd0 : rom_addr;
          rom_addr  <= gray_done ? 18'd0 : rom_addr + 1;
          ram_addr  <= gray_done ? 18'd0 : pixel_cnt;
          gray_done <= ram_addr == 18'd262143;
        end
        CP_R: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 1;
        end
        RP_R: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd513;
        end
        LRP_R: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd512;
        end
        LCP_R: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd511;
        end
        LLP_R: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt;
        end
        CP_W: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 1;
        end
        RP_W: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd513;
        end
        LRP_W: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd512;
        end
        LCP_W: begin
          pixel_cnt <= pixel_cnt;
          rom_addr  <= 18'd0;
          ram_addr  <= pixel_cnt + 18'd511;
        end
        LLP_W: begin
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
        ram_idata = 8'd0;
        valid_i   = 1'b0;
      end
      GRAY: begin
        rom_en    = 1'b1;
        ram_ren   = 1'b0;
        ram_wen   = 1'b1;
        ram_idata = gray_o;
        valid_i   = 1'b0;
      end
      CP_R: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b1;
        ram_wen   = 1'b0;
        ram_idata = 8'b0;
        valid_i   = 1'b0;
      end
      RP_R: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[8:0] != 9'd511);
        ram_wen   = 1'b0;
        ram_idata = 8'b0;
        valid_i   = 1'b1;
      end
      LRP_R: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[8:0] != 9'd511) && (pixel_cnt[17:9] != 9'd511);
        ram_wen   = 1'b0;
        ram_idata = 8'b0;
        valid_i   = 1'b0;
      end
      LCP_R: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[17:9] != 9'd511);
        ram_wen   = 1'b0;
        ram_idata = 8'b0;
        valid_i   = 1'b0;
      end
      LLP_R: begin
        rom_en    = 1'b0;
        ram_ren   = (pixel_cnt[17:9] != 9'd511) && (pixel_cnt[8:0] != 9'd0);
        ram_wen   = 1'b0;
        ram_idata = 8'b0;
        valid_i   = 1'b0;
      end
      CP_W: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = 1'b1;
        ram_idata = diff_o[0];
        valid_i   = 1'b0;
      end
      RP_W: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[8:0] != 9'd511);
        ram_idata = diff_o[1];
        valid_i   = 1'b0;
      end
      LRP_W: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[8:0] != 9'd511) && (pixel_cnt[17:9] != 9'd511);
        ram_idata = diff_o[2];
        valid_i   = 1'b0;
      end
      LCP_W: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[17:9] != 9'd511);
        ram_idata = diff_o[3];
        valid_i   = 1'b0;
      end
      LLP_W: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = (pixel_cnt[17:9] != 9'd511) && (pixel_cnt[8:0] != 9'd0);
        ram_idata = diff_o[4];
        valid_i   = 1'b0;
      end
      default: begin
        rom_en    = 1'b0;
        ram_ren   = 1'b0;
        ram_wen   = 1'b0;
        ram_idata = 8'd0;
        valid_i   = 1'b0;
      end
    endcase
  end


endmodule

