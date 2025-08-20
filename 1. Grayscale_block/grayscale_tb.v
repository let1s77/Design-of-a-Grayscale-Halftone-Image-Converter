`timescale 1ns/10ps
`define INTERVAL 0.5 // hint: this line has mistake

`ifdef SYN
    `include "/usr/cad/CBDK/Nangate45/2010.12/Front_End/Verilog/NangateOpenCellLibrary.v"
    `include "grayscale_syn.v"
`else
    `include "grayscale.v"
`endif


module grayscale_tb;
	
	reg [23:0] pattern [0:9];
	reg [7:0] golden [29:0];
	integer i, err;


	reg [23:0] color;
	reg [1:0] mode;
	wire [7:0] gray;
	
  
	grayscale dut (
		.mode	(mode),
		.color	(color),
		.gray	(gray)
	);

	// mem initialization
	initial begin
		$readmemh("pattern.hex", pattern);
		$readmemh("golden.hex", golden);
	end
  
	// Start simulation
	initial begin
		err = 0;
		mode = 0;
		color = 0;
		
		for(i=0;i<10;i=i+1)begin

			mode = 0;
			color = pattern[i];
			#`INTERVAL;
			$display("------------- Pattern %d: %h -------------", i+1, color);
			if(gray===golden[3*i])
				$display("Round-up is correct.");
			else begin
				$display("Round-up is wrong. Your result is %d, but %d is expected.", gray, golden[3*i]);
				err = err + 1;
			end

			mode = 1;
			#`INTERVAL;
			if(gray===golden[3*i+1])
				$display("Round-down is correct.");
			else begin
				$display("Round-down is wrong. Your result is %d, but %d is expected.", gray, golden[3*i+1]);
				err = err + 1;
			end

			mode = 2;
			#`INTERVAL;
			if(gray===golden[3*i+2])
				$display("Round-to-even is correct.");
			else begin
				$display("Round-to-even is wrong. Your result is %d, but %d is expected.", gray, golden[3*i+2]);
				err = err + 1;
			end

		end
		
		if(err===0)begin
		`ifdef SYN
			$display("        ****************************               ");
			$display("        **       Lab2 - SYN       **               ");
		`else
			$display("        ****************************               ");
			$display("        **       Lab2 - RTL       **               ");
		`endif
			$display("        ****************************               ");
			$display("        **                        **       |\__||  ");
			$display("        **  Congratulations !!    **      / O.O  | ");
			$display("        **                        **    /_____   | ");
			$display("        **  SIMULATION PASS !!     **   /^ ^ ^ \\  |");
			$display("        **                        **  |^ ^ ^ ^ |w| ");
			$display("        ****************************   \\m___m__|_|");
			$display("\n");
		end
		else begin
		`ifdef SYN
			$display("        ****************************               ");
			$display("        **       Lab2 - SYN       **               ");
		`else
			$display("        ****************************               ");
			$display("        **       Lab2 - RTL       **               ");
		`endif
			$display("        ****************************               ");
			$display("        **                        **       |\__||  ");
			$display("        **  OOPS!!                **      / X,X  | ");
			$display("        **                        **    /_____   | ");
			$display("        **  SIMULATION Failed!!   **   /^ ^ ^ \\  |");
			$display("        **                        **  |^ ^ ^ ^ |w| ");
			$display("        ****************************   \\m___m__|_|");
			$display("         Totally has %d errors                     ", err); 
			$display("\n");
		end
		$finish;
	end
	
	`ifdef SYN
    	initial $sdf_annotate("grayscale_syn.sdf", dut);
	`endif

	`ifdef FSDB
		initial begin
		$fsdbDumpfile("grayscale.fsdb");
		$fsdbDumpvars("+struct", "+mda", dut);
		end
	`endif
  
endmodule
  
