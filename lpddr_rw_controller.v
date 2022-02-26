`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:12:45 03/17/2021 
// Design Name: 
// Module Name:    lpddr_rw_controller 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lpddr_rw_controller#(parameter auto_precharge=0,parameter write_read_sel=0)
	(	clk,rst,
	//input
	burst_length,data_addr,data_en,data_in,data_out,data_mask,
	
	rd_set,rd_en_set,rd_cmd_set,rd_addr_set,
	
	//output to lpddr port 
	cmd_clk,cmd_en,cmd_instr,cmd_bl,cmd_byte_addr,cmd_empty,cmd_full,

	w_r_clk,w_r_en,w_r_mask,w_data,r_data,w_r_full,w_r_empty,w_r_count,w_r_underrun,w_r_error
    );
	
	input				clk;
	input				rst;
	input [5:0]			burst_length;
	input [29:0]		data_addr;
	input 				data_en;
	input [3:0]			data_mask; 
	
	input 				rd_set;
	input 				rd_en_set;
	input				rd_cmd_set;
	input [29:0]		rd_addr_set;
	
	input [31:0] 		data_in;
	output [31:0] 		data_out;
	
	output				cmd_clk;
	output				cmd_en;
	output [2:0]		cmd_instr;	
	output [5:0]		cmd_bl;
	output [29:0]		cmd_byte_addr;
	input				cmd_empty;
	input				cmd_full;

	output				w_r_clk;
	output				w_r_en;
	output [3:0]		w_r_mask;
	

	input  [31:0] r_data;
	output [31:0] w_data;
		
	input				w_r_full;
	input				w_r_empty;
	input  [6:0]		w_r_count;
	input				w_r_underrun;
	input				w_r_error;

	//intermediate signal
	reg				r_cmd_en;	
	reg [29:0]		r_cmd_byte_addr;
	reg 			   r_w_r_en;
	reg [3:0]	   r_w_r_mask;
	reg [31:0]	   r_wr_data;
	
	reg [5:0]		burst_count;
	wire           ready;

	assign cmd_clk   	= clk;
	assign w_r_clk   	= clk;
	assign cmd_instr 	= {1'b0,auto_precharge,write_read_sel}; //000 write; 001 read ;010 write with auto precharge ;011 read with auto_precharge
	assign cmd_bl    	= burst_length;
	assign cmd_en		= r_cmd_en;
	assign cmd_byte_addr= r_cmd_byte_addr;//{r_cmd_byte_addr[27:11],r_cmd_byte_addr[29:28],r_cmd_byte_addr[10:2],2'b00};
	assign w_r_en    	= r_w_r_en;
	assign w_r_mask  	= r_w_r_mask;
	
	generate
		if(write_read_sel==0)
			assign w_data   = r_wr_data;
		else
			assign data_out = r_wr_data; // (!w_r_empty)?r_data:0;
	endgenerate
	
	assign ready        = (!w_r_full)&(data_en);
	
	generate 
		if(write_read_sel == 0) begin //write
			always@(posedge clk) 
				if(rst) begin 
					r_cmd_en        <= 1'b0;
					r_cmd_byte_addr <= 0;
					r_w_r_en        <= 0;
					r_w_r_mask      <= 4'b0000;
					r_wr_data       <= 0;
					burst_count		<= 0;
				end
				else begin 
					if(ready) begin 
						r_w_r_en  <= 1'b1;
						r_wr_data <= data_in;
						r_w_r_mask <= data_mask;
						if(burst_count == burst_length)  
							burst_count <= 0;
						else 
							burst_count <= burst_count+1'b1;
						
						if(!cmd_full) 
							if(burst_count == burst_length) begin 
								r_cmd_en <= 1;
								r_cmd_byte_addr <= (data_addr*4)-(burst_length*4);
							end 
							else begin 
								r_cmd_en <= 0;
								r_cmd_byte_addr <= cmd_byte_addr;//{cmd_byte_addr[12:11],cmd_byte_addr[29:13],cmd_byte_addr[10:0]};
							end 
						else begin 
							r_cmd_byte_addr <= cmd_byte_addr;//{cmd_byte_addr[12:11],cmd_byte_addr[29:13],cmd_byte_addr[10:0]};
							r_cmd_en <= 0;
							//synthesis translate off
							if(burst_count == burst_length) begin $display("comment fifo fill");$stop; end 
							//synthesis translate on
						end 	
					end
					else begin 
						r_w_r_en <= 1'b0;
						r_cmd_en <= 0;
						r_cmd_byte_addr <= cmd_byte_addr;//{cmd_byte_addr[12:11],cmd_byte_addr[29:13],cmd_byte_addr[10:0]};
						//synthesis translate off
						if(data_en) begin $display("write fifo fill");$stop; end 
						//synthesis translate on
					end 
				end 
		end 
		else begin 
			always@(posedge clk) 
				if(rst) begin 
					r_cmd_en        <= 1'b0;
					r_cmd_byte_addr <= 0;
					r_w_r_en        <= 0;
					//r_w_r_mask      <= 4'b0000;
					r_wr_data       <= 0;
					burst_count		<= 0;
				end
				else begin 
					if(ready & !rd_set) begin 
						r_w_r_en  <= 1'b1;
						r_wr_data <= r_data;
						if(burst_count == 0) begin 
							if(!cmd_full) begin 
								r_cmd_en <= 1;
								r_cmd_byte_addr <= (data_addr*4);
								burst_count <= burst_length;
							end 
							else begin
								$display("comment fifo fill");$stop;
								r_cmd_en <= 0;
								r_cmd_byte_addr <= cmd_byte_addr;//{cmd_byte_addr[12:11],cmd_byte_addr[29:13],cmd_byte_addr[10:0]};
								burst_count <= 0;
							end 
						end
						else begin 
							r_cmd_en <= 0;
							r_cmd_byte_addr <= cmd_byte_addr;//{cmd_byte_addr[12:11],cmd_byte_addr[29:13],cmd_byte_addr[10:0]};
							burst_count <= burst_count - 1;
						end 
					end
					else if(rd_set) begin 
						r_wr_data 		<= r_data;
						r_w_r_en 		<= rd_en_set;
						r_cmd_en		<= rd_cmd_set;
						r_cmd_byte_addr <= (rd_addr_set*4);
						burst_count 	<= 0;
					end 
					else begin 
						r_cmd_en <= 0;
						r_cmd_byte_addr <= cmd_byte_addr;//{cmd_byte_addr[12:11],cmd_byte_addr[29:13],cmd_byte_addr[10:0]};
						//burst_count <= 0;
						r_w_r_en  <= 1'b0;
						if(data_en) begin $display("read fifo fill");$stop; end 
					end 
				end 
		end 
	endgenerate
	
endmodule
