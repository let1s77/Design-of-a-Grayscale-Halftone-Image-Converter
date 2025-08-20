`timescale 1ns/10ps

`ifdef SYN
`include "../syn/error_diffusion_syn.v"
`include "/usr/cad/CBDK/Nangate45/2010.12/Front_End/Verilog/NangateOpenCellLibrary.v"
`else
`include "C:/Users/Ms Khanh/OneDrive - hcmut.edu.vn/Desktop/img_proj/2. Error Diffusion Block/Testbench_Error_Diffusion_Block/src/error_diffusion.v"
`endif
// ---------------------- define ---------------------- //
`define Pixel_DataSize	8
`define clkPeriod 3
`define Tb_Num 4
`define MAXCYCLE 100

module error_diffusion_tb;
	reg clk;
	reg rst;
	reg valid_i;
	reg [`Pixel_DataSize-1:0] data_i;
	wire done;
	wire [`Pixel_DataSize-1:0] result0;
	wire [`Pixel_DataSize-1:0] result1;
	wire [`Pixel_DataSize-1:0] result2;
	wire [`Pixel_DataSize-1:0] result3;
	wire [`Pixel_DataSize-1:0] result4;

	integer err,i,j;
	reg [`Pixel_DataSize-1:0] pattern_all [0:`Tb_Num*5-1];
	reg [`Pixel_DataSize-1:0] golden_all [0:`Tb_Num*5-1];
	reg [`Pixel_DataSize-1:0] pattern1 [0:5-1];
	reg [`Pixel_DataSize-1:0]  golden1 [0:5-1];
	reg [`Pixel_DataSize-1:0] pattern2 [0:5-1];
	reg [`Pixel_DataSize-1:0]  golden2 [0:5-1];
	reg [`Pixel_DataSize-1:0] pattern3 [0:5-1];
	reg [`Pixel_DataSize-1:0]  golden3 [0:5-1];
	reg [`Pixel_DataSize-1:0] pattern4 [0:5-1];
	reg [`Pixel_DataSize-1:0]  golden4 [0:5-1];
	reg [`Pixel_DataSize-1:0] pattern [0:5-1];
	reg [`Pixel_DataSize-1:0]  golden [0:5-1];
	reg [2:0] cnt;
	integer cycle_cnt;
	
	error_diffusion dut(
		.clk	 (clk		),
		.rst_n	 (rst		),
		.valid_i (valid_i	),	
		.data_i	 (data_i	),
		.done	 (done		),
		
	 	.result0 (result0),
		.result1 (result1),
		.result2 (result2),
		.result3 (result3),
		.result4 (result4)
	);
	
	always #(`clkPeriod/2) clk = ~clk;
	
	initial begin
		$readmemh("C:/Users/Ms Khanh/OneDrive - hcmut.edu.vn/Desktop/img_proj/2. Error Diffusion Block/Testbench_Error_Diffusion_Block/sim/pattern.hex", pattern_all);
		$readmemh("C:/Users/Ms Khanh/OneDrive - hcmut.edu.vn/Desktop/img_proj/2. Error Diffusion Block/Testbench_Error_Diffusion_Block/sim/golden.hex", golden_all);
		for(j=0;j<5;j=j+1) begin
			pattern1[j] = pattern_all[j];
			golden1[j]  = golden_all[j];
			pattern2[j] = pattern_all[5+j];
			golden2[j]  = golden_all[5+j];
			pattern3[j] = pattern_all[10+j];
			golden3[j]  = golden_all[10+j];
			pattern4[j] = pattern_all[15+j];
			golden4[j]  = golden_all[15+j];
		end

		`ifdef tb1
		$display("----------- Pattern 1 start simulation -----------");
		begin
			for(j=0;j<5;j=j+1) begin
				pattern[j] = pattern1[j];
				golden[j]  = golden1[j];
			end
		end
		`elsif tb2
		$display("----------- Pattern 2 start simulation -----------");
		begin
			for(j=0;j<5;j=j+1) begin
				pattern[j] = pattern2[j];
				golden[j]  = golden2[j];
			end
		end
		`elsif tb3
		$display("----------- Pattern 3 start simulation -----------");
		begin
			for(j=0;j<5;j=j+1) begin
				pattern[j] = pattern3[j];
				golden[j]  = golden3[j];
			end
		end
		`elsif tb4
		$display("----------- Pattern 4 start simulation -----------");
		begin
			for(j=0;j<5;j=j+1) begin
				pattern[j] = pattern4[j];
				golden[j]  = golden4[j];
			end
		end
		`endif
	end
	
	always@(posedge clk /*or posedge rst*/) begin
		if(~rst) begin
			data_i <= 8'd0;
			valid_i <= 1'b0;
			cnt <= 3'd0;
			cycle_cnt <= 'd0;
		end
		else begin
			cnt <= (cnt == 3'd5) ? cnt : (cnt+3'd1);
			data_i <= (cnt == 3'd5) ? 8'd0 : pattern[cnt];
			valid_i <= (cnt == 3'd5) ? 1'b0 : 1'b1;
			cycle_cnt <= cycle_cnt + 'd1;
		end
	end
	
	initial begin
		clk = 0;
		rst = 0;
		err = 0;
		@(posedge clk)
		@(posedge clk) rst = 1;
		wait(done);
		@(posedge clk);
		for(i=0; i<5;i=i+1) begin
			case(i)
				0: begin
					if(result0===golden[i]) $display("Center pixel is correct!\n");
					else begin 
						$display("Center pixel is wrong! Your value is %d, the correct result is %d\n",result0,golden[i]);
						err = err + 1;
					end
				end
				1: begin
					if(result1===golden[i]) $display("Right pixel is correct!\n");
					else begin 
						$display("Right pixel is wrong! Your value is %d, the correct result is %d\n",result1,golden[i]);
						err = err + 1;
					end
				end
				2: begin
					if(result2===golden[i]) $display("Lower right pixel is correct!\n");
					else begin 
						$display("Lower right pixel is wrong! Your value is %d, the correct result is %d\n",result2,golden[i]);
						err = err + 1;
					end
				end
				3: begin
					if(result3===golden[i]) $display("Lower center pixel is correct!\n");
					else begin 
						$display("Lower center pixel is wrong! Your value is %d, the correct result is %d\n",result3,golden[i]);
						err = err + 1;
					end
				end
				4: begin
					if(result4===golden[i]) $display("Lower left pixel is correct!\n");
					else begin 
						$display("Lower left pixel is wrong! Your value is %d, the correct result is %d\n",result4,golden[i]);
						err = err + 1;
					end
				end
			endcase
		end
	
	
		if(err===0)begin
			$display("        ****************************               ");
			$display("        **                        **       |\__||  ");
			$display("        **  Congratulations !!    **      / O.O  | ");
			$display("        **                        **    /_____   | ");
			$display("        **  SIMULATION PASS !!    **    /^ ^ ^ \\ | ");
			$display("        **                        **  |^ ^ ^ ^ |w| ");
			$display("        ****************************   \\m___m__|_| ");
			$display("        Your cycle count: %d.", cycle_cnt);
			$display("\n");
		end
		else begin
			$display("        ****************************               ");
			$display("        **                        **       |\__||  ");
			$display("        **  OOPS!!                **      / X,X  | ");
			$display("        **                        **    /_____   | ");
			$display("        **  SIMULATION FAILED!!   **   /^ ^ ^ \\ | ");
			$display("        **                        **  |^ ^ ^ ^ |w| ");
			$display("        ****************************  \\m___m__|_| ");
			$display("         Totally has %d errors                     ", err); 
			$display("\n");
		end
		$finish;
	end
	
	`ifdef SYN
		initial begin	$sdf_annotate("../syn/error_diffusion_syn.sdf",dut); end
	`endif	
	initial begin
		#(`MAXCYCLE*`clkPeriod)
		$display("        ************************************************               ");
		$display("        **                        			        **       |\__||  ");
		$display("        **  OOPS!!                			        **      / X,X  | ");
		$display("        **                        			        **    /_____   | ");
		$display("        **  SIMULATION CANNOT TERMINATE PROPERLY!!   	**   /^ ^ ^ \\ | ");
		$display("        **                        			        **  |^ ^ ^ ^ |w| ");
		$display("        ************************************************  \\m___m__|_| s");
		$display("\n");
		$finish;
	end
	
	initial begin
	`ifdef FSDB
		$fsdbDumpfile("error_diffusion.fsdb");
		$fsdbDumpvars("+struct", "+mda", dut);
	`endif
	end
	
endmodule
