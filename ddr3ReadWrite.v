`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:37:45 06/28/2021 
// Design Name: 
// Module Name:    ddr3ReadWrite 
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

module ddr3ReadWrite(
	
	input 		 sd_ddr_clk_in,
	input 		 ddr_word_sel,
	input [31:0] sd_ddr_data_in,
	input 		 sd_ddr_wren_in ,
	input [29:0] sd_ddr_addr_in,
	
	input 		 cam_ddr_clk_in,
	input [31:0] cam_ddr_data_in,
	input 		 cam_ddr_wren_in ,
	input [29:0] cam_ddr_addr_in,
	
	input 			vga_clk,
	input			vga_rst,
	output 			vga_en,
	input 			vsync,
	input 			vga_rd_en,
	output [31:0]	rgb_data,
	
	input 			port5_rd_clk,
	output 	[31:0]  port5_rd_data,
	input 			port5_rd_en,
	input 	[29:0]  port5_rd_addr,
	
	input 			clk312,
	input          	c3_sys_rst_i,
	output 			calib_rst,

	inout   [15:0] mcb3_dram_dq,
	output  [13:0] mcb3_dram_a,
	output  [2:0]  mcb3_dram_ba,
	output         mcb3_dram_ras_n,
	output         mcb3_dram_cas_n,
	output         mcb3_dram_we_n,
	output         mcb3_dram_odt,
	output         mcb3_dram_reset_n,
	output         mcb3_dram_cke,
	output         mcb3_dram_dm,
	inout          mcb3_dram_udqs,
	inout          mcb3_dram_udqs_n,
	inout          mcb3_rzq,
	inout          mcb3_zio,
	output         mcb3_dram_udm,
	inout          mcb3_dram_dqs,
	inout          mcb3_dram_dqs_n,
	output         mcb3_dram_ck,
	output         mcb3_dram_ck_n
    );


	//--port 2 write 
	wire				c3_p2_cmd_clk;
	wire				c3_p2_cmd_en;
	wire[2:0]			c3_p2_cmd_instr;	
	wire[5:0]			c3_p2_cmd_bl;
	wire[29:0]			c3_p2_cmd_byte_addr;
	wire				c3_p2_cmd_empty;
	wire				c3_p2_cmd_full;

	wire				c3_p2_wr_clk;
	wire				c3_p2_wr_en;
	wire[3:0]			c3_p2_wr_mask;
	wire[31:0]			c3_p2_wr_data;
	wire				c3_p2_wr_full;
	wire				c3_p2_wr_empty;
	wire[6:0]			c3_p2_wr_count;
	wire				c3_p2_wr_underrun;
	wire				c3_p2_wr_error;
	///--port 3 write 
	wire				c3_p3_cmd_clk;
	wire				c3_p3_cmd_en;
	wire[2:0]			c3_p3_cmd_instr;	
	wire[5:0]			c3_p3_cmd_bl;
	wire[29:0]			c3_p3_cmd_byte_addr;
	wire				c3_p3_cmd_empty;
	wire				c3_p3_cmd_full;

	wire				c3_p3_wr_clk;
	wire				c3_p3_wr_en;
	wire[3:0]			c3_p3_wr_mask;
	wire[31:0]			c3_p3_wr_data;
	wire				c3_p3_wr_full;
	wire				c3_p3_wr_empty;
	wire[6:0]			c3_p3_wr_count;
	wire				c3_p3_wr_underrun;
	wire				c3_p3_wr_error;
	///--port 4 read 
	wire 				c3_p4_cmd_clk;
	wire				c3_p4_cmd_en;
	wire [2:0]			c3_p4_cmd_instr;
	wire [5:0]			c3_p4_cmd_bl;
	wire [29:0]			c3_p4_cmd_byte_addr;
	wire				c3_p4_cmd_empty;
	wire				c3_p4_cmd_full;
	
	wire 				c3_p4_rd_clk;
	wire				c3_p4_rd_en;
	wire [3:0]			c3_p4_rd_mask;
	wire [31:0]			c3_p4_rd_data;
	wire				c3_p4_rd_full;
	wire				c3_p4_rd_empty;
	wire [6:0]			c3_p4_rd_count;
	wire				c3_p4_rd_underrun;
	wire				c3_p4_rd_error;

	///--port 5 read 
	wire 				c3_p5_cmd_clk;
	wire				c3_p5_cmd_en;
	wire [2:0]			c3_p5_cmd_instr;
	wire [5:0]			c3_p5_cmd_bl;
	wire [29:0]			c3_p5_cmd_byte_addr;
	wire				c3_p5_cmd_empty;
	wire				c3_p5_cmd_full;
	
	wire 				c3_p5_rd_clk;
	wire				c3_p5_rd_en;
	wire [3:0]			c3_p5_rd_mask;
	wire [31:0]			c3_p5_rd_data;
	wire				c3_p5_rd_full;
	wire				c3_p5_rd_empty;
	wire [6:0]			c3_p5_rd_count;
	wire				c3_p5_rd_underrun;
	wire				c3_p5_rd_error;
	
	wire 				c3_clk0;
	wire 				c3_rst0;
	wire    		 	c3_calib_done;
	
	assign calib_rst = c3_rst0 || !c3_calib_done;
	
	//wire [3:0 ] data_mask;
	//wire [31:0] ddr_data_in;
	wire [29:0]ddr_wr_addr;
	wire [29:0]ddr_rd_addr;
	
	reg ddr_buf_sel;
	
	always@(posedge vga_clk)
		if(calib_rst)
			ddr_buf_sel <= 0;
		else if(vsync)
			ddr_buf_sel <= ddr_word_sel;
	
	//assign data_mask = (ddr_word_sel) ? 4'b0011 : 4'b1100;
	//assign ddr_data_in = (ddr_word_sel) ? {sd_ddr_data_in[15:0],sd_ddr_data_in[31:16]} : sd_ddr_data_in;
	assign ddr_wr_addr = (ddr_word_sel) ? 384000 : 0; 
	assign ddr_rd_addr = (ddr_buf_sel) ? 0 : 384000;
	
	lpddr_rw_controller #(
		.auto_precharge(1'b1),
		.write_read_sel(1'b0)  // 0 - write 1- read
	)
	lpddr_port2_write (
		.clk(sd_ddr_clk_in), 
		.rst(calib_rst),
		
		.burst_length(6'd0), 
		.data_addr(sd_ddr_addr_in+ddr_wr_addr ),//
		.data_en(sd_ddr_wren_in), 
		.data_in(sd_ddr_data_in), //ddr_data_in
		.data_mask(4'b0000), //data_mask
		
		.cmd_clk(c3_p2_cmd_clk), 
		.cmd_en(c3_p2_cmd_en), 
		.cmd_instr(c3_p2_cmd_instr), 
		.cmd_bl(c3_p2_cmd_bl), 
		.cmd_byte_addr(c3_p2_cmd_byte_addr), 
		.cmd_empty(c3_p2_cmd_empty), 
		.cmd_full(c3_p2_cmd_full), 
		
		.w_r_clk(c3_p2_wr_clk), 
		.w_r_en(c3_p2_wr_en), 
		.w_r_mask(c3_p2_wr_mask), 
		.w_data(c3_p2_wr_data), 
		.w_r_full(c3_p2_wr_full), 
		.w_r_empty(c3_p2_wr_empty), 
		.w_r_count(c3_p2_wr_count), 
		.w_r_underrun(c3_p2_wr_underrun), 
		.w_r_error(c3_p2_wr_error)
    );
	
	
	////////////////////////
	// lpddr_rw_controller #(
		// .auto_precharge(1'b1),
		// .write_read_sel(1'b0)  // 0 - write 1- read
	// )
	// lpddr_port3_write (
		// .clk(cam_ddr_clk_in), 
		// .rst(calib_rst),
		
		// .burst_length(6'd31), 
		// .data_addr(cam_ddr_addr_in), 
		// .data_en(cam_ddr_wren_in), 
		// .data_in(cam_ddr_data_in), 
		// .data_mask(4'b0011), 
		
		// .cmd_clk(c3_p3_cmd_clk), 
		// .cmd_en(c3_p3_cmd_en), 
		// .cmd_instr(c3_p3_cmd_instr), 
		// .cmd_bl(c3_p3_cmd_bl), 
		// .cmd_byte_addr(c3_p3_cmd_byte_addr), 
		// .cmd_empty(c3_p3_cmd_empty), 
		// .cmd_full(c3_p3_cmd_full), 
		
		// .w_r_clk(c3_p3_wr_clk), 
		// .w_r_en(c3_p3_wr_en), 
		// .w_r_mask(c3_p3_wr_mask), 
		// .w_data(c3_p3_wr_data), 
		// .w_r_full(c3_p3_wr_full), 
		// .w_r_empty(c3_p3_wr_empty), 
		// .w_r_count(c3_p3_wr_count), 
		// .w_r_underrun(c3_p3_wr_underrun), 
		// .w_r_error(c3_p3_wr_error)
    // );

	//wire [31:0] rgb_temp;
	wire [31:0]	vga_rd_data;
	wire [29:0] vga_addr;
	wire 		rd_set;
	wire  		rd_en_set;
	wire  		rd_cmd_set;

	wire line_en;
	
	//assign rgb_data = (ddr_buf_sel) ? rgb_temp : {rgb_temp[15:0],rgb_temp[31:16]};
	
	line_buffer vga_line_buffer (
		.clk(vga_clk), 
		.rst(calib_rst), 
		.vga_rd_en(vga_rd_en), 
		.vga_rst(vga_rst), 
		.vga_data(rgb_data), //rgb_temp
		.vga_en(vga_en),
		.vsync(vsync),
		.ddr_rd_addr(vga_addr), 
		.ddr_rd_data(vga_rd_data), 
		.read_fifo_empty(c3_p4_rd_empty),
		.ddr_rd_en(line_en), 
		.line_rd_set(rd_set), 
		.line_cmd_set(rd_cmd_set), 
		.line_en_set(rd_en_set)
    );	

	lpddr_rw_controller #(
		.auto_precharge(1'b1),
		.write_read_sel(1'b1)  // 0 - write 1- read
	)
	lpddr_port4_read (
		.clk(vga_clk), 
		.rst(calib_rst),
		
		.burst_length(6'd31), 
		.data_addr(vga_addr+ddr_rd_addr ),//
		.data_en(line_en), 
		.data_out(vga_rd_data), 
		.data_mask(4'b0000), 
		
		.rd_set(rd_set),
		.rd_en_set(rd_en_set),
		.rd_cmd_set(rd_cmd_set),
		.rd_addr_set(vga_addr+ddr_rd_addr),//
		
		.cmd_clk(c3_p4_cmd_clk), 
		.cmd_en(c3_p4_cmd_en), 
		.cmd_instr(c3_p4_cmd_instr), 
		.cmd_bl(c3_p4_cmd_bl), 
		.cmd_byte_addr(c3_p4_cmd_byte_addr), 
		.cmd_empty(c3_p4_cmd_empty), 
		.cmd_full(c3_p4_cmd_full), 
		
		.w_r_clk(c3_p4_rd_clk), 
		.w_r_en(c3_p4_rd_en), 
		.w_r_mask(), 
		.r_data(c3_p4_rd_data), 
		.w_r_full(c3_p4_rd_full), 
		.w_r_empty(c3_p4_rd_empty), 
		.w_r_count(c3_p4_rd_count), 
		.w_r_underrun(), //c3_p5_rd_underrun
		.w_r_error(c3_p4_rd_error)
    );
	
	
	// lpddr_rw_controller #(
		// .auto_precharge(1'b1),
		// .write_read_sel(1'b1)  // 0 - write 1- read
	// )
	// lpddr_port5_read (
		// .clk(port5_rd_clk), 
		// .rst(calib_rst),
		
		// .burst_length(6'd31), 
		// .data_addr(port5_rd_addr), 
		// .data_en(port5_rd_en), 
		// .data_out(port5_rd_data), 
		// .data_mask(4'b0000), 
		
		// .rd_set(1'b0),
		// .rd_en_set(),
		// .rd_cmd_set(),
		// .rd_addr_set(),
		
		// .cmd_clk(c3_p5_cmd_clk), 
		// .cmd_en(c3_p5_cmd_en), 
		// .cmd_instr(c3_p5_cmd_instr), 
		// .cmd_bl(c3_p5_cmd_bl), 
		// .cmd_byte_addr(c3_p5_cmd_byte_addr), 
		// .cmd_empty(c3_p5_cmd_empty), 
		// .cmd_full(c3_p5_cmd_full), 
		
		// .w_r_clk(c3_p5_rd_clk), 
		// .w_r_en(c3_p5_rd_en), 
		// .w_r_mask(), 
		// .r_data(c3_p5_rd_data), 
		// .w_r_full(c3_p5_rd_full), 
		// .w_r_empty(c3_p5_rd_empty), 
		// .w_r_count(c3_p5_rd_count), 
		// .w_r_underrun(), //c3_p5_rd_underrun
		// .w_r_error(c3_p5_rd_error)
    // );

///////////////////////////////////////

	ddr3_mig # (
		.C3_P0_MASK_SIZE(4),
		.C3_P0_DATA_PORT_SIZE(32),
		.C3_P1_MASK_SIZE(4),
		.C3_P1_DATA_PORT_SIZE(32),
		.DEBUG_EN(0),
		.C3_MEMCLK_PERIOD(3200),
		.C3_CALIB_SOFT_IP("TRUE"),
		.C3_SIMULATION("FALSE"),
		.C3_RST_ACT_LOW(0),
		.C3_INPUT_CLK_TYPE("SINGLE_ENDED"),
		.C3_MEM_ADDR_ORDER("ROW_BANK_COLUMN"),
		.C3_NUM_DQ_PINS(16),
		.C3_MEM_ADDR_WIDTH(14),
		.C3_MEM_BANKADDR_WIDTH(3)
	)
	u_ddr3_mig (

	.c3_sys_clk           (clk312),
	.c3_sys_rst_i         (~c3_sys_rst_i),                        

	.mcb3_dram_dq           (mcb3_dram_dq),  
	.mcb3_dram_a            (mcb3_dram_a),  
	.mcb3_dram_ba           (mcb3_dram_ba),
	.mcb3_dram_ras_n        (mcb3_dram_ras_n),                        
	.mcb3_dram_cas_n        (mcb3_dram_cas_n),                        
	.mcb3_dram_we_n         (mcb3_dram_we_n),                          
	.mcb3_dram_odt          (mcb3_dram_odt),
	.mcb3_dram_cke          (mcb3_dram_cke),                          
	.mcb3_dram_ck           (mcb3_dram_ck),                          
	.mcb3_dram_ck_n         (mcb3_dram_ck_n),       
	.mcb3_dram_dqs          (mcb3_dram_dqs),                          
	.mcb3_dram_dqs_n        (mcb3_dram_dqs_n),
	.mcb3_dram_udqs         (mcb3_dram_udqs),    // for X16 parts                        
	.mcb3_dram_udqs_n       (mcb3_dram_udqs_n),  // for X16 parts
	.mcb3_dram_udm          (mcb3_dram_udm),     // for X16 parts
	.mcb3_dram_dm           (mcb3_dram_dm),
	.mcb3_dram_reset_n      (mcb3_dram_reset_n),
  
	.c3_clk0		          (c3_clk0),
	.c3_rst0		          (c3_rst0),
	.c3_calib_done    	  (c3_calib_done),
  
   .mcb3_rzq               (mcb3_rzq),          
   .mcb3_zio               (mcb3_zio),
	
//   .c3_p0_cmd_clk                          (c3_p0_cmd_clk),
//   .c3_p0_cmd_en                           (c3_p0_cmd_en),
//   .c3_p0_cmd_instr                        (c3_p0_cmd_instr),
//   .c3_p0_cmd_bl                           (c3_p0_cmd_bl),
//   .c3_p0_cmd_byte_addr                    (c3_p0_cmd_byte_addr),
//   .c3_p0_cmd_empty                        (c3_p0_cmd_empty),
//   .c3_p0_cmd_full                         (c3_p0_cmd_full),
//   .c3_p0_wr_clk                           (c3_p0_wr_clk),
//   .c3_p0_wr_en                            (c3_p0_wr_en),
//   .c3_p0_wr_mask                          (c3_p0_wr_mask),
//   .c3_p0_wr_data                          (c3_p0_wr_data),
//   .c3_p0_wr_full                          (c3_p0_wr_full),
//   .c3_p0_wr_empty                         (c3_p0_wr_empty),
//   .c3_p0_wr_count                         (c3_p0_wr_count),
//   .c3_p0_wr_underrun                      (c3_p0_wr_underrun),
//   .c3_p0_wr_error                         (c3_p0_wr_error),
//   .c3_p0_rd_clk                           (c3_p0_rd_clk),
//   .c3_p0_rd_en                            (c3_p0_rd_en),
//   .c3_p0_rd_data                          (c3_p0_rd_data),
//   .c3_p0_rd_full                          (c3_p0_rd_full),
//   .c3_p0_rd_empty                         (c3_p0_rd_empty),
//   .c3_p0_rd_count                         (c3_p0_rd_count),
//   .c3_p0_rd_overflow                      (c3_p0_rd_overflow),
//   .c3_p0_rd_error                         (c3_p0_rd_error),
//   .c3_p1_cmd_clk                          (c3_p1_cmd_clk),
//   .c3_p1_cmd_en                           (c3_p1_cmd_en),
//   .c3_p1_cmd_instr                        (c3_p1_cmd_instr),
//   .c3_p1_cmd_bl                           (c3_p1_cmd_bl),
//   .c3_p1_cmd_byte_addr                    (c3_p1_cmd_byte_addr),
//   .c3_p1_cmd_empty                        (c3_p1_cmd_empty),
//   .c3_p1_cmd_full                         (c3_p1_cmd_full),
//   .c3_p1_wr_clk                           (c3_p1_wr_clk),
//   .c3_p1_wr_en                            (c3_p1_wr_en),
//   .c3_p1_wr_mask                          (c3_p1_wr_mask),
//   .c3_p1_wr_data                          (c3_p1_wr_data),
//   .c3_p1_wr_full                          (c3_p1_wr_full),
//   .c3_p1_wr_empty                         (c3_p1_wr_empty),
//   .c3_p1_wr_count                         (c3_p1_wr_count),
//   .c3_p1_wr_underrun                      (c3_p1_wr_underrun),
//   .c3_p1_wr_error                         (c3_p1_wr_error),
//   .c3_p1_rd_clk                           (c3_p1_rd_clk),
//   .c3_p1_rd_en                            (c3_p1_rd_en),
//   .c3_p1_rd_data                          (c3_p1_rd_data),
//   .c3_p1_rd_full                          (c3_p1_rd_full),
//   .c3_p1_rd_empty                         (c3_p1_rd_empty),
//   .c3_p1_rd_count                         (c3_p1_rd_count),
//   .c3_p1_rd_overflow                      (c3_p1_rd_overflow),
//   .c3_p1_rd_error                         (c3_p1_rd_error),
   .c3_p2_cmd_clk                          (c3_p2_cmd_clk),
   .c3_p2_cmd_en                           (c3_p2_cmd_en),
   .c3_p2_cmd_instr                        (c3_p2_cmd_instr),
   .c3_p2_cmd_bl                           (c3_p2_cmd_bl),
   .c3_p2_cmd_byte_addr                    (c3_p2_cmd_byte_addr),
   .c3_p2_cmd_empty                        (c3_p2_cmd_empty),
   .c3_p2_cmd_full                         (c3_p2_cmd_full),
   .c3_p2_wr_clk                           (c3_p2_wr_clk),
   .c3_p2_wr_en                            (c3_p2_wr_en),
   .c3_p2_wr_mask                          (c3_p2_wr_mask),
   .c3_p2_wr_data                          (c3_p2_wr_data),
   .c3_p2_wr_full                          (c3_p2_wr_full),
   .c3_p2_wr_empty                         (c3_p2_wr_empty),
   .c3_p2_wr_count                         (c3_p2_wr_count),
   .c3_p2_wr_underrun                      (c3_p2_wr_underrun),
   .c3_p2_wr_error                         (c3_p2_wr_error),
   // .c3_p3_cmd_clk                          (c3_p3_cmd_clk),
   // .c3_p3_cmd_en                           (c3_p3_cmd_en),
   // .c3_p3_cmd_instr                        (c3_p3_cmd_instr),
   // .c3_p3_cmd_bl                           (c3_p3_cmd_bl),
   // .c3_p3_cmd_byte_addr                    (c3_p3_cmd_byte_addr),
   // .c3_p3_cmd_empty                        (c3_p3_cmd_empty),
   // .c3_p3_cmd_full                         (c3_p3_cmd_full),
   // .c3_p3_wr_clk                           (c3_p3_wr_clk),
   // .c3_p3_wr_en                            (c3_p3_wr_en),
   // .c3_p3_wr_mask                          (c3_p3_wr_mask),
   // .c3_p3_wr_data                          (c3_p3_wr_data),
   // .c3_p3_wr_full                          (c3_p3_wr_full),
   // .c3_p3_wr_empty                         (c3_p3_wr_empty),
   // .c3_p3_wr_count                         (c3_p3_wr_count),
   // .c3_p3_wr_underrun                      (c3_p3_wr_underrun),
   // .c3_p3_wr_error                         (c3_p3_wr_error),
   .c3_p4_cmd_clk                          (c3_p4_cmd_clk),
   .c3_p4_cmd_en                           (c3_p4_cmd_en),
   .c3_p4_cmd_instr                        (c3_p4_cmd_instr),
   .c3_p4_cmd_bl                           (c3_p4_cmd_bl),
   .c3_p4_cmd_byte_addr                    (c3_p4_cmd_byte_addr),
   .c3_p4_cmd_empty                        (c3_p4_cmd_empty),
   .c3_p4_cmd_full                         (c3_p4_cmd_full),
   .c3_p4_rd_clk                           (c3_p4_rd_clk),
   .c3_p4_rd_en                            (c3_p4_rd_en),
   .c3_p4_rd_data                          (c3_p4_rd_data),
   .c3_p4_rd_full                          (c3_p4_rd_full),
   .c3_p4_rd_empty                         (c3_p4_rd_empty),
   .c3_p4_rd_count                         (c3_p4_rd_count),
   .c3_p4_rd_overflow                      (c3_p4_rd_overflow),
   .c3_p4_rd_error                         (c3_p4_rd_error),
   .c3_p5_cmd_clk                          (c3_p5_cmd_clk),
   .c3_p5_cmd_en                           (c3_p5_cmd_en),
   .c3_p5_cmd_instr                        (c3_p5_cmd_instr),
   .c3_p5_cmd_bl                           (c3_p5_cmd_bl),
   .c3_p5_cmd_byte_addr                    (c3_p5_cmd_byte_addr),
   .c3_p5_cmd_empty                        (c3_p5_cmd_empty),
   .c3_p5_cmd_full                         (c3_p5_cmd_full),
   .c3_p5_rd_clk                           (c3_p5_rd_clk),
   .c3_p5_rd_en                            (c3_p5_rd_en),
   .c3_p5_rd_data                          (c3_p5_rd_data),
   .c3_p5_rd_full                          (c3_p5_rd_full),
   .c3_p5_rd_empty                         (c3_p5_rd_empty),
   .c3_p5_rd_count                         (c3_p5_rd_count),
   .c3_p5_rd_overflow                      (c3_p5_rd_overflow),
   .c3_p5_rd_error                         (c3_p5_rd_error)
 );




endmodule
