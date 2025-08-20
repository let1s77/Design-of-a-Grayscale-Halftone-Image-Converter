///////////////////////////////////////////////////                   
//   Author: LPHP Lab                            // 
//   Project: Simple image processor testbench   //
///////////////////////////////////////////////////


`timescale 1ns/10ps
`define CYCLE 8               // modify the clock period if needed
`define MAX_CYCLE  40000000   // modify the maximum number of clock cycle if needed

`include "../src/ROM.v"
`include "../src/RAM.v"


`ifdef SYN
    `include "/usr/cad/CBDK/Nangate45/2010.12/Front_End/Verilog/NangateOpenCellLibrary.v"
    `include "../syn/top_syn.v"
`else
    `include "../src/top.v"
`endif

module testfixture();

logic        clk = 0;
logic        rst_n = 0;
logic        gray_DONE;
logic        diff_DONE;
logic        rom_en;
logic [17:0] rom_addr;
logic [23:0] rom_data;
logic        ram_ren;
logic        ram_wen;
logic [17:0] ram_addr;
logic [7:0]  ram_idata;
logic [7:0]  ram_odata;

typedef enum logic [2:0] {
    RST_state, GRAY_state, DIFF_state, CHECK_state
}fsm;
fsm state = RST_state;

always begin #(`CYCLE/2) clk = ~clk; end

top i_TOP(
    .clk          (clk      ),
    .rst_n        (rst_n    ),
    .gray_done    (gray_DONE),
    .diff_done    (diff_DONE),

    // rom port
    .rom_en       (rom_en   ),
    .rom_addr     (rom_addr ),
    .rom_data     (rom_data ),
    
    // ram port
    .ram_ren      (ram_ren  ),
    .ram_wen      (ram_wen  ),
    .ram_addr     (ram_addr ),
    .ram_idata    (ram_idata),
    .ram_odata    (ram_odata)
);

ROM i_ROM (
    .CLK  (clk),
    .REN  (rom_en),
    .A    (rom_addr),
    .Q    (rom_data)
);

RAM i_RAM (
    .CLK  (clk),
    .REN  (ram_ren),
    .WEN  (ram_wen),
    .A    (ram_addr),
    .D    (ram_idata),
    .Q    (ram_odata)
);


// pattern definition
`ifdef P1  // tux image
    string pattern_name     = "../sim/image/Tux.bmp";
    string gray_name        = "../sim/image/gray_Tux.bmp";
    string dot_name         = "../sim/image/dot_Tux.bmp";

    string gray_golden_name = "../sim/golden/G1/gray_Tux_Golden.dat";
    string dot_golden_name  = "../sim/golden/G1/dot_Tux_Golden.dat";
    string deb_golden_name  = "../sim/golden/G1/debug_file_Tux.dat"; // golden of error diffusion without saturation
    integer verify_design   = 1;

`elsif P2  // little mole
    string pattern_name     = "../sim/image/Little-Mole.bmp";
    string gray_name        = "../sim/image/gray_Little-Mole.bmp";
    string dot_name         = "../sim/image/dot_Little-Mole.bmp";

    string gray_golden_name = "../sim/golden/G2/gray_LM_Golden.dat";
    string dot_golden_name  = "../sim/golden/G2/dot_LM_Golden.dat";
    string deb_golden_name  = "../sim/golden/G2/debug_file_LM.dat"; // golden of error diffusion without saturation
    integer verify_design   = 1;

`elsif TEST // Generate your own image
    string pattern_name     = "../sim/image/xiu_mai.bmp";
    string gray_name        = "../sim/image/gray_test.bmp";
    string dot_name         = "../sim/image/dot_test.bmp";

    // no golden to verify
    string gray_golden_name = "";
    string dot_golden_name  = "";
    string deb_golden_name  = ""; 
    integer verify_design   = 0;
`else
    // Default values for undefined macros
    string bmp_name         = "";
    string gray_golden_name = "";
    string dot_golden_name  = "";
    string deb_golden_name  = "";
    integer verify_design   = 0;
    
    initial begin
        $display("Error: You cannot see this sentence, need to define the macro when simulation");
        $finish;
    end
`endif



`ifdef DEBUG_MODE
    integer debug_mode = 1;
`else
    integer debug_mode = 0;
`endif

integer gray_error = -1;
integer dot_error = -1;
integer fp;
integer tmp;
logic [127:0] pat;
logic [7:0]   header      [53:0];
logic [7:0]   read_img;
logic [7:0]   gray_golden [512*512-1 : 0];
logic [7:0]   dot_golden  [512*512-1 : 0];
logic [7:0]   deb_golden  [512*512-1 : 0];
//logic [7:0] img [512*512*3-1 : 0];

// read bmp image as pattern, and diffusion golden
initial begin
    fp = $fopen(pattern_name, "rb");
    if (!fp) begin
        $display("Error: cannot open file: %s !", pattern_name);
        $finish;
    end
    // read header
    for (int i=0; i<54; i=i+1)begin
        header[i] = $fgetc(fp);
    end
    // read rgb image
    for (int i=0; i<512*512*3; i=i+1)begin
        read_img = $fgetc(fp);
        
        case (i%3)
            0: i_ROM.mem[i/3][23:16] = read_img; // Blue
            1: i_ROM.mem[i/3][15: 8] = read_img; // Green
            2: i_ROM.mem[i/3][ 7: 0] = read_img; // Rad
            default: $display("Error: cannot reach this sentance! (i mod 3)");
        endcase
        
    end
    $fclose(fp);

    if (verify_design) begin
        $readmemh(gray_golden_name, gray_golden);
        $readmemh(dot_golden_name,  dot_golden);
        $readmemh(deb_golden_name,  deb_golden);
    end
end


always @(posedge clk) begin
    case (state)
        RST_state: begin
            #(`CYCLE/2) state <= GRAY_state;
            #(`CYCLE/2) rst_n <= 1;
        end
        GRAY_state: begin
            if (diff_DONE === 1)      state <= CHECK_state;
            else if (gray_DONE === 1) state <= DIFF_state;
            else                      state <= GRAY_state;

            if (gray_DONE === 1) begin
                plot_gray();
                if (verify_design) compare(0);
                $display("Waiting the design assert the diff_done signal ....");
            end
            if (diff_DONE === 1) begin   
                if (debug_mode == 1 && verify_design == 1)
                    compare(2); // compare with before saturation golden
                else begin
                    plot_dot();
                    if (verify_design) compare(1); // compare with after saturation golden
                end
            end
        end
        DIFF_state: begin
            state <= (diff_DONE === 1)? CHECK_state : DIFF_state;

            if (diff_DONE === 1) begin
                if (debug_mode == 1 && verify_design == 1)
                    compare(2); // compare with before saturation golden
                else begin
                    plot_dot();
                    if (verify_design) compare(1); // compare with after saturation golden
                end
            end
        end
        CHECK_state: begin
            state <= RST_state;
            
        end
        default: begin
            state <= RST_state;
        end
    endcase
end


`ifdef SYN
    initial $sdf_annotate("../syn/top_syn.sdf", i_TOP);
`endif


// generate waveform
initial begin
    `ifdef FSDB
        $fsdbDumpfile("top.fsdb");
        $fsdbDumpvars;
    `elsif FSDB_ALL
        $fsdbDumpfile("top.fsdb");
        $fsdbDumpvars("+struct", "+mda", i_TOP);
        //$fsdbDumpvars("+struct", "+mda", i_ROM);
        $fsdbDumpvars("+struct", "+mda", i_RAM);
    `endif
end



// out of simulation time
initial begin
    # (`MAX_CYCLE);
    $display("\n");
    $display("\n");
`ifdef SYN
	$display("        ****************************               ");
	$display("        **       Lab6 - SYN       **               ");
`else
	$display("        ****************************               ");
	$display("        **       Lab6 - RTL       **               ");
`endif
    $display("        ****************************               ");
    $display("        **                        **       |\__||  ");
    $display("        **  OOPS!!                **      / X,X  | ");
    $display("        **                        **    /_____   | ");
    $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
    $display("        **                        **  |^ ^ ^ ^ |w| ");
    $display("        ****************************   \\m___m__|_|");
    $display("\n");
    $display("!!! Reach maximum cycle number !!!");
    plot_dot();

    // need to print some score
    if (gray_error == -1) $display("Error: Without comparing grayscale with golden");
    if (dot_error == -1)  $display("Error: Without comparing error diffusion with golden");
    $finish;
end

task compare;
    input [1:0] mode; // 0: grayscale, 1: diffusion after saturation, 2: diffusion before saturation
    
    if (mode == 0) begin
        gray_error = 0;
        for (int i=0; i<$size(gray_golden); i=i+1) begin
            if (gray_golden[i] !== i_RAM.mem[i]) begin
                if (gray_error <= 10) $display("RAM mem[%d] = %h, golden is %h", i, i_RAM.mem[i], gray_golden[i]);
                gray_error ++;
            end
        end

        if (gray_error > 10) $display("Error: Grayscale is more then 10 error");
        if (gray_error == 0)  $display("Grayscale is OK");
    end

    if (mode == 1) begin
        dot_error = 0;
        for (int i=0; i<$size(dot_golden); i=i+1) begin
            if (dot_golden[i] !== i_RAM.mem[i]) begin
                if (dot_error <= 10) $display("RAM mem[%d] = %h, golden is %h, coord is (%d, %d)", 
                                            i, i_RAM.mem[i], dot_golden[i], i%512, i/512);
                dot_error ++;
            end
        end

        if (dot_error > 10) $display("Error: error diffusion is more then 10 error");
        if (dot_error == 0)  $display("Error diffusion is OK");
    end

    if (mode == 2) begin
        dot_error = 0;
        for (int i=0; i<$size(deb_golden); i=i+1) begin
            if (deb_golden[i] !== i_RAM.mem[i]) begin
                if (dot_error <= 100) $display("RAM mem[%d] = %h, debug is %h, coord is (%d, %d)", 
                                               i, i_RAM.mem[i], deb_golden[i], i%512, i/512);
                dot_error ++;
            end
        end

        if (dot_error > 10) $display("Error: error diffusion is more then 10 error. (debug mode)");
        if (dot_error == 0)  $display("Error diffusion without saturation is OK. (debug mode)");
    end

	

    if (dot_error == 0 && (mode == 1 || mode == 2)) begin
        $display("\n");
        $display("\n");
`ifdef SYN
		$display("        ****************************               ");
		$display("        **       Lab6 - SYN       **               ");
`else
		$display("        ****************************               ");
		$display("        **       Lab6 - RTL       **               ");
`endif
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  Congratulations !!    **      / O.O  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
        if (mode == 1)
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        else if (mode == 2)
        $display("        **       DEBUG Mode       **  |^ ^ ^ ^ |w| ");

        $display("        ****************************   \\m___m__|_|");
        $display("\n");
        $finish;
    end

    if ( (gray_error != 0 || dot_error != 0) && (mode == 1 || mode == 2)) begin
        $display("\n");
        $display("\n");
`ifdef SYN
		$display("        ****************************               ");
		$display("        **       Lab6 - SYN       **               ");
`else
		$display("        ****************************               ");
		$display("        **       Lab6 - RTL       **               ");
`endif
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  OOPS!!                **      / X,X  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
        if (mode == 1)
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        else if (mode == 2)
        $display("        **       DEBUG Mode       **  |^ ^ ^ ^ |w| ");

        $display("        ****************************   \\m___m__|_|");
        $display("\n");
        
        // need to print some score
        if (gray_error == -1)     $display("Without comparing grayscale with golden");
        else if (gray_error != 0) $display("There are %d errors in Grayscale.", gray_error);
         
        if (dot_error == -1)      $display("Without comparing error diffusion with golden");
        else if (dot_error  != 0) $display("There are %d errors in Error diffusion.", dot_error);
        

        $finish;
    end
endtask



task plot_gray;
    integer obmp;

    $display("Plot grayscale image ...");

    obmp = $fopen(gray_name, "wb");
    // write header
    for(int i=0; i<54; i=i+1) begin
        $fwrite(obmp, "%c", header[i]);
    end

    // write image pixel
    for(int i=0; i<512*512; i=i+1) begin
        $fwrite(obmp, "%c", i_RAM.mem[i]);
        $fwrite(obmp, "%c", i_RAM.mem[i]);
        $fwrite(obmp, "%c", i_RAM.mem[i]);
    end

    $display("The grayscale image had been generated in the file \"sim/image\" \n\n");
    $fclose(obmp);
endtask

task plot_dot;
    integer obmp;

    $display("Plot dot image ...");

    obmp = $fopen(dot_name, "wb");
    // write header
    for(int i=0; i<54; i=i+1) begin
        $fwrite(obmp, "%c", header[i]);
    end

    // write image pixel after error diffusion
    for (int i=0; i<512; i=i+1) begin  // reverse to x-axis
        for (int j=0; j<512; j=j+1) begin
			if (i_RAM.mem[i*512 + j] == 'd255)begin
				$fwrite(obmp, "%c", 255);
				$fwrite(obmp, "%c", 255);
				$fwrite(obmp, "%c", 255);
			end
			else if (i_RAM.mem[i*512 + j] == 'd0) begin
				$fwrite(obmp, "%c", 0);
				$fwrite(obmp, "%c", 0);
				$fwrite(obmp, "%c", 0);
				//$fwrite(obmp, "*");
			end
			else begin
				$fwrite(obmp, "%c", "X");
				$fwrite(obmp, "%c", "X");
				$fwrite(obmp, "%c", "X");
			end

	end
    end
    

    $display("The dot image had been generated in the file \"sim/image\" \n\n");
    $fclose(obmp);
    if (!verify_design) begin
        $display("Your own image \"%s\" had been successfully convert.\n\n", pattern_name);
        $finish;
    end
endtask


endmodule
