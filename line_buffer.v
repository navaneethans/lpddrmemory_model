module line_buffer(
		clk,rst,

		vga_rd_en,vga_rst,vga_data,vga_en,vsync,
		
		ddr_rd_addr,ddr_rd_data,read_fifo_empty,ddr_rd_en,
		line_rd_set,line_cmd_set,line_en_set
	);

	input clk;
	input rst;
	
	//vga 
	input vga_rd_en;
	input vga_rst;
	output [31:0]vga_data; 
	output vga_en;
	input vsync;
	
	//lpddr fifo 
	output [29:0] ddr_rd_addr;
	input  [31:0] ddr_rd_data;
	input 		  read_fifo_empty;
	output        ddr_rd_en;
	output		  line_rd_set;
	output 		  line_cmd_set;
	output	 	  line_en_set;	
	
	
	wire fifo_rd;
	reg fifo_we;
	wire fifo_full, fifo_empty;//fifo_threshold, fifo_overflow, fifo_underflow;  
	wire prog_full;
	
	wire [31:0]wr_data;
	reg [29:0]rd_addr;
	reg ddr_rd_set,ddr_set_cmd,ddr_set_en;
	reg rd_en;
	
	reg [3:0]state;
	reg vga_en_r;
	
	assign line_rd_set  = ddr_rd_set;
	assign line_cmd_set = ddr_set_cmd;
	assign line_en_set  = ddr_set_en; 
	assign ddr_rd_addr  = rd_addr+4;
	assign vga_en 		= vga_en_r;
	assign ddr_rd_en    = rd_en;
	
	localparam line_ideal = 0 ;
	localparam line_read_set_empty = 1 ;
	localparam line_read_set = 2;
	localparam line_read = 3 ;
	localparam line_fifo_fill = 4;
	localparam line_fifo_rw = 5 ;
	
	reg vsync_r;
	
	always@(posedge clk)
		if(rst) 
			vsync_r <= 0;
		else 
			vsync_r <= vsync;
	
	always@(posedge clk)
		if(rst) begin 
			state 		 <= line_ideal;
			fifo_we 	 <= 0;
			ddr_rd_set	 <= 0;
			ddr_set_cmd	 <= 0;
			ddr_set_en	 <= 0;
			rd_addr      <= 0;
			vga_en_r	 <= 0;
			rd_en        <= 0;
		end
		else begin
			case(state)
				line_ideal : begin 
					if(~vga_rst) begin 
						state <= line_read_set_empty;
					end 
				end 
				line_read_set_empty : begin 
					if(read_fifo_empty && fifo_empty) begin 
						state <= line_read_set;
						rd_addr      	 <= 0;
						ddr_rd_set		 <= 1;
						ddr_set_cmd		 <= 1;
						ddr_set_en		 <= 0;
					end 
					else if(~read_fifo_empty) begin 
						rd_addr      	 <= 0;
						ddr_rd_set		 <= 1;
						ddr_set_cmd		 <= 0;
						ddr_set_en		 <= 1;
					end 
					else begin 
						rd_addr      	 <= 0;
						ddr_rd_set		 <= 1;
						ddr_set_cmd		 <= 0;
						ddr_set_en		 <= 0;
					end 
				end 
				line_read_set : begin 
					state 		<= line_fifo_rw; //line_fifo_fill;
					rd_addr 	<= 29;//31;
					ddr_rd_set	<= 0;
					ddr_set_cmd	<= 0;
					ddr_set_en	<= 0;
					$display("fifo fill");
				end 
				/* line_fifo_fill : begin 
					// if(~vsync) begin 
						// rd_en	<= 0;
						// fifo_we <= rd_en;
						////rd_addr <= 0;
						// state 	<= line_fifo_rw;
					// end 
					// else 
					if(~prog_full)
						if(!read_fifo_empty) begin 
							rd_en	<= 1'b1;
							fifo_we 	<= rd_en ;
							rd_addr <= rd_addr + 1;
							if(~vsync) state 	<= line_fifo_rw; 
						end 
						else begin
							fifo_we 	<= rd_en ;
							rd_en	<= 1'b0;
							if(~vsync) state 	<= line_fifo_rw; 
						end
					else begin 
						rd_en	<= 1'b0;
						fifo_we <= rd_en;
						if(~vsync) state 	<= line_fifo_rw; 
						//vga_en_r <= 1;
						//state <= line_fifo_rw;
					end 	
				end  */
				line_fifo_rw : begin
					if((!vsync_r) & vsync) begin 
						rd_en	<= 0;
						fifo_we <= 0;
						rd_addr <= 0;
						state 	<= line_ideal;
					end 
					else if(~prog_full)
						if((!read_fifo_empty)) begin 
							rd_en	<= 1'b1;
							fifo_we 	<= rd_en ;
							rd_addr <= rd_addr + 1;
						end 
						else begin
							fifo_we 	<= rd_en ;
							rd_en	<= 1'b0;
						end
					else begin 
						rd_en	<= 1'b0;
						fifo_we <= rd_en;
						vga_en_r <= 1;
						//state <= line_fifo_rw;
					end  
				end
			endcase
		end 
	
	assign wr_data = ddr_rd_data;
	assign fifo_rd = (ddr_rd_set) ? ~fifo_empty : vga_rd_en;
	
	line_fifo  line_fifo_0(
		.clk(clk), // input clk
		.rst(rst), // input rst
		.din(wr_data), // input [31 : 0] din
		.wr_en(fifo_we), // input wr_en
		.rd_en(fifo_rd), // input rd_en
		.dout(vga_data), // output [31 : 0] dout
		.full(fifo_full), // output full
		.empty(fifo_empty), // output empty
		.prog_full(prog_full) // output prog_full
	);
	
	
endmodule		