/*
 * @Author: Tomood
 * @Date: 2024-11-18 21:33:43
 * @LastEditors: Tomood
 * @LastEditTime: 2024-12-01 19:43:19
 * @FilePath: \Gowin-Tang-Primer-20K-DDR3-AXI-Stream-FIFO-Warpper\src\ddr3_rw_controller.v
 * @Description: gowin 20K DDR3 mem interface ip axi4 stream fifo wrapper
 * Copyright (c) 2024 by Tomood, All Rights Reserved. 
 */

/*读写通道仲裁优先级:rd < wr*/
module ddr3_rw_controller # (
	parameter DDR_MAX_DNUM = 16'hff //ddr最大数据个数
)(
    //sys signal
    input  wire          clk,
    input  wire          rst_n,
	output wire 	     init_calib_complete, //ddr ip init done
	//usr fifo interface wr (axis slave)
	input  wire          s_axis_aclk,         // fifo wr_clk
	output wire          s_axis_tready,       // axi slave ready
	input  wire          s_axis_tvaild,       // axi master vaild(fifo wr_en)
	input  wire [15:0]	 s_axis_tdata,        // fifo wr_data
	//usr fifo interface rd (axis master)
	input  wire          m_axis_aclk,         // fifo rd_clk
	input  wire          m_axis_tready,       // axi slave ready(fifo rd_en)
	output wire          m_axis_tvaild,       // axi master vaild
	output wire [15:0]	 m_axis_tdata,        // fifo wr_data
    //ddr sdram interface
    output wire [12:0]   O_ddr_addr,
	output wire [2: 0]   O_ddr_ba,
	output wire          O_ddr_cs_n,
	output wire          O_ddr_ras_n,
	output wire          O_ddr_cas_n,
	output wire          O_ddr_we_n,
	output wire          O_ddr_clk,
	output wire          O_ddr_clk_n,
	output wire          O_ddr_cke,
	output wire          O_ddr_odt,
	output wire          O_ddr_reset_n,
	output wire [1: 0]   O_ddr_dqm,
	inout  wire [15: 0]  IO_ddr_dq,
	inout  wire [1: 0]   IO_ddr_dqs,
	inout  wire [1: 0]   IO_ddr_dqs_n 
);

/*********************************************************************************/
/****************************** wires & regs define ******************************/
/*********************************************************************************/
//for user logic
wire          app_clk		       ; //app_clk: ip's output clk for app logic
//addr cmd channal
wire          app_rdy  		       ;
reg  [  2:0]  app_cmd  		       ; 
reg           app_en   		       ;
reg  [ 26:0]  app_addr 		       ; //27bit addr deepth for 1Gbit DDR3
//wdata channal       
wire          app_wdf_rdy          ;
wire [  7:0]  app_wdf_mask         ;
wire [127:0]  app_wdf_data         ;
wire          app_wdf_wren         ;
wire          app_wdf_end          ;
//rdata channal       
wire [127:0]  app_rd_data          ;
wire          app_rd_data_vaild    ; 

//memory_clk:pll output to ddr3 sdram
wire memory_clk;
//ddr_rst: ddr3 ip's rst for user (high vaild)
wire ddr_rst;
//pll_lock: pll lock signal
wire pll_lock;



//buffer fifo
wire [5:0] 	 wr_fifo_wnum   ; //读数据缓存fifo的写侧(user axis侧)同步水位信号
wire [2:0] 	 wr_fifo_rnum   ; //写数据缓存fifo的读侧(ddr    ip侧)同步水位信号
wire [2:0] 	 rd_fifo_wnum   ; //读数据缓存fifo的写侧(ddr    ip侧)同步水位信号
wire [5:0] 	 rd_fifo_rnum   ; //读数据缓存fifo的读侧(user axis侧)同步水位信号


//ddr wrapper
reg        	 ddr_wr_req     ;  //写数据缓存fifo的传输请求
reg        	 ddr_rd_req     ;  //读数据缓存fifo的传输请求

reg [1:0]    ddr_wr_req_cd	; //write cool down time 
reg [16-1:0] ddr_wr_ptr	    ; //ddr封装成fifo的写地址指针 128bit
reg [16-1:0] ddr_rd_ptr	    ; //ddr封装成fifo的读地址指针 128bit
reg [16-1:0] ddr_dat_num    ; //ddr内部存有数据的个数 128bit*num
wire         ddr_full	    ; //ddr full
wire         ddr_empty	    ; //ddr empty

reg [2:0]	 ddr_rd_req_cnt ; //ddr读请求计数器 记录目前正在处理的读请求的个数

/*********************************************************************************/
/******************************        fsm          ******************************/
/*********************************************************************************/
//fsm param
localparam IDLE     = 4'b0001;  //空闲状态
localparam ARBIT    = 4'b0010;  //仲裁状态
localparam WRITE    = 4'b0100;  //写准备状态
localparam READ     = 4'b1000;  //读命令状态

//fsm
reg [3:0] cstate ;//current state
reg [3:0] nstate ;//next state

//1st fsm
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n)
		cstate <= IDLE;
	else 
		cstate <= nstate;
end

//2nd fsm
always @(*) begin
	case (cstate)
		IDLE: begin
			if(init_calib_complete)begin//wait mig ip init done
				nstate = ARBIT;
			end else begin
				nstate = IDLE;
			end
		end
		ARBIT:begin
			if(ddr_wr_req & app_rdy & app_wdf_rdy & !ddr_full)begin//wr first
				//fifo满足写条件 & cmd通道ready & 写数据通道ready & ddr没有被写满
				nstate = WRITE;
			end else if(ddr_rd_req & app_rdy & !ddr_empty) begin //读
				//fifo满足读条件 & cmd通道ready & ddr没有被读空 才能接受读命令
				nstate = READ;
			end else begin
				nstate = ARBIT;//没有请求或不满足条件 保持仲裁状态
			end
		end
		WRITE:begin
			if(app_wdf_end) begin //all data wr done
				nstate = ARBIT;
			end else begin
				nstate = WRITE;
			end
		end
		READ:begin //send read command status
			if(app_rdy && app_en) begin//握手成功即命令发送完成
				nstate = ARBIT;
			end else begin
				nstate = READ;
			end
		end
		default: begin
			nstate = IDLE; 
		end
	endcase
end

/*********************************************************************************/
/******************************     main code       ******************************/
/*********************************************************************************/

//app_wdf_wren:ddr3写数据通道数据有效信号
assign app_wdf_wren = (cstate==WRITE);
//wr_data_end:在时钟速度为1:4,突发为BL8下 last信号应与en同步
assign app_wdf_end = app_wdf_wren;


///ddr_wr_req_cd:写请求cd,用于只写入了一个数据时的状态
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n) begin
		ddr_wr_req_cd <= 1'b0;
	end else if((wr_fifo_rnum == 1) && (cstate == WRITE))begin
		//当写缓存FIFO中只有一个数据,且正在发送时
		ddr_wr_req_cd <= 2'd3;//set cd time,防止读一次数据后ddr_wr_fifo水位未及时更新而重复读空fifo
	end else if(ddr_wr_req_cd != 2'b00)begin
		ddr_wr_req_cd <= ddr_wr_req_cd - 1'b1;
	end
end

//ddr_wr_req: 写数据缓存fifo的传输请求
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n) begin
		ddr_wr_req <= 1'b0;
	end else if((wr_fifo_rnum == 1) && (ddr_wr_req_cd == 2'd0) && (cstate != WRITE))begin
		ddr_wr_req <= 1'b1;//如果只有1个数据 需要等待cd 且不允许连续请求(防止wrfifo水位更新不及时导致错误)
	end else if(wr_fifo_rnum > 1) begin
		//当水位满足大于突发长度
		ddr_wr_req <= 1'b1;//请求ddr ip 发送
	end else begin
		ddr_wr_req <= 1'b0;
	end
end

//ddr_rd_req: 读数据缓存fifo的传输请求
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n) begin
		ddr_rd_req <= 1'b0;
	end else if (rd_fifo_wnum + ddr_rd_req_cnt < 2) begin
		//当rd fifo 的写时钟域同步水位小于2(包括已经向DDR IP请求了 但尚未返回的数据)
		ddr_rd_req <= 1'b1;//请求ddr ip 读取
	end else begin
		ddr_rd_req <= 1'b0;
	end
end

//ddr_rd_req_cnt: ddr读请求计数器 记录目前正在处理的读请求的个数
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n) begin
		ddr_rd_req_cnt <= 0;
	end else if ((cstate==READ) && app_rd_data_vaild) begin
		ddr_rd_req_cnt <= ddr_rd_req_cnt;
	end else if ((cstate!=READ) && app_rd_data_vaild) begin
		ddr_rd_req_cnt <= ddr_rd_req_cnt - 1'b1;
	end else if ((cstate==READ) && !app_rd_data_vaild) begin
		ddr_rd_req_cnt <= ddr_rd_req_cnt + 1'b1;
	end
end

//ddr_addr_ptr:ddr封装成fifo的地址指针
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n) begin
		ddr_dat_num <= 0;
	end else if((cstate==WRITE) && !ddr_full) begin
		//往ddr里写入了数据 且 没有被写满
		ddr_dat_num <= ddr_dat_num + 1'b1;
	end else if((cstate==READ) && !ddr_empty)begin
		//如果有读取请求发出(无论数据是否已经返回) 且 没有被读空
		ddr_dat_num <= ddr_dat_num - 1'b1;
	end
end

//ddr_wr_ptr:ddr封装成fifo的写地址指针(目前深度只使用到16bit)
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n)begin
		ddr_wr_ptr <= 0;
	end else if((cstate==WRITE) && !ddr_full) begin
		ddr_wr_ptr <= ddr_wr_ptr + 1'b1;
	end
end

//ddr_rd_ptr:ddr封装成fifo的读地址指针(目前深度只使用到16bit)
always @(posedge app_clk or negedge rst_n) begin
	if(!rst_n)begin
		ddr_rd_ptr <= 0;
	end else if((cstate==READ) && !ddr_empty) begin
		ddr_rd_ptr <= ddr_rd_ptr + 1'b1;
	end
end

//ddr3 mig ip的地址命令通道信号控制
always @(*) begin
	case(cstate)
		WRITE:
			begin
				app_addr = {8'b0,ddr_wr_ptr[15:0],3'b0};//地址x8 转换为dq地址写入
				app_cmd  = 3'b000;//wr
				app_en   = 1'b1;
			end
		READ: 
			begin
				app_addr = {8'b0,ddr_rd_ptr[15:0],3'b0};//地址x8 转换为dq地址写入
				app_cmd  = 3'b001;//rd
				app_en   = 1'b1;
			end
		default: 
			begin
				app_addr = 0;//地址x8 转换为字节地址写入
				app_cmd  = 3'b0;
				app_en   = 1'b0;
			end
	endcase
end

//s_axis_tready:用户fifo写axi slave端口的握手信号输出
assign s_axis_tready = (wr_fifo_wnum != 5'b11111);//防止把输入fifo写满

//m_axis_tvaild:用户fifo读axi master端口的握手信号输出
/** The axi stream protocol requires that the tvaild be low during reset **/
assign m_axis_tvaild = (rd_fifo_rnum != 5'b00000) & (rst_n);//防止把输出fifo读空

//ddr_full : ddr memory is full
assign ddr_full = (ddr_dat_num == DDR_MAX_DNUM);

//ddr_empty: ddr memory is empty
assign ddr_empty = (ddr_dat_num == 16'h00);

/*********************************************************************************/
/******************************    instantiation    ******************************/
/*********************************************************************************/

//为ddr ip提供时钟的pll
DDR_rPLL u_DDR_rPLL(
    .clkin  (clk),          //input clkin
    .clkout (memory_clk),   //output clkout 400Mhz
    .lock   (pll_lock)      //output lock
);

//ddr写数据通道缓冲fifo
ddr_wr_fifo u_ddr_wr_fifo(
	.Reset    (!rst_n),
	//wr data channel
	.WrClk    (s_axis_aclk),       //input WrClk
	.WrEn     (s_axis_tvaild),     //input WrEn
	.Data	  (s_axis_tdata),      //input [15:0] Data
	//rd data channel
	.RdClk	  (app_clk), 		   //input RdClk
	.RdEn	  (app_wdf_wren),      //input RdEn 输入给fifo的读使能信号要提前ddr的wr_data_en
	.Q		  (app_wdf_data), 	   //output [127:0] Q
	//sys status
	.Wnum	  (wr_fifo_wnum), 	    //output [4:0] Wnum 同步写时钟域
	.Rnum	  (wr_fifo_rnum), 	   //output [3:0] Rnum 同步读时钟域
	.Empty    (/*dont care*/),     //output Empty
	.Full     (/*dont care*/)      //output Full
);

//ddr读数据通道缓冲fifo
ddr_rd_fifo u_ddr_rd_fifo(
	.Reset    (!rst_n),
	//wr data channel
	.WrClk    (app_clk),            //input WrClk
	.WrEn     (app_rd_data_vaild),  //input WrEn
	.Data	  (app_rd_data),        //input [127:0] Data
	//rd data channel
	.RdClk	  (m_axis_aclk),    	//input RdClk
	.RdEn	  (m_axis_tready), 		//input RdEn
	.Q		  (m_axis_tdata), 		//output [15:0] Q
	//sys status
	.Wnum	  (rd_fifo_wnum), 	    //output [4:0] Wnum 同步写时钟域
	.Rnum     (rd_fifo_rnum),       //output [5:0] Rnum 同步读时钟域
	.Empty    (/*dont care*/),      //output Empty
	.Full     (/*dont care*/)       //output Full
);

//ddr3 MIG IP core native接口
DDR3_Memory_Interface_Top u_DDR3_Memory_Interface_Top(
    //sys
	.clk                (clk),                  //input clk
	.memory_clk         (memory_clk),           //input memory_clk
	.pll_lock           (pll_lock),             //input pll_lock
	.rst_n              (rst_n),                //input rst_n
	.clk_out            (app_clk),              //output clk_out
	.ddr_rst            (/*dont care*/),        //output ddr_rst
	.init_calib_complete(init_calib_complete),  //output init_calib_complete
    //cmd channel
	.cmd_ready          (app_rdy),          	//output cmd_ready
	.cmd                (app_cmd),              //input [2:0] cmd
	.cmd_en             (app_en),               //input cmd_en
	.addr               (app_addr),             //input [26:0] addr
    //wr data channal interface
	.wr_data_rdy        (app_wdf_rdy),          //output wr_data_rdy
	.wr_data_mask       (16'h0000),             //input [15:0] wr_data_mask
	.wr_data            (app_wdf_data),         //input [127:0] wr_data
	.wr_data_en         (app_wdf_wren),         //input wr_data_en
	.wr_data_end        (app_wdf_end),          //input wr_data_end
    //rd data channal
	.rd_data            (app_rd_data),          //output [127:0] rd_data
	.rd_data_valid      (app_rd_data_vaild),    //output rd_data_valid
	.rd_data_end        (/*dont care*/),        //output rd_data_end
    //other ctrl signal
	.sr_req             (1'b0),                 //input sr_req
	.ref_req            (1'b0),                 //input ref_req
	.sr_ack             (/*dont care*/),        //output sr_ack
	.ref_ack            (/*dont care*/),        //output ref_ack
	.burst              (1'b1),                 //input burst
    //ddr mem interface
	.O_ddr_addr         (O_ddr_addr),           //output [12:0] O_ddr_addr
	.O_ddr_ba           (O_ddr_ba),             //output [2:0] O_ddr_ba
	.O_ddr_cs_n         (O_ddr_cs_n),           //output O_ddr_cs_n
	.O_ddr_ras_n        (O_ddr_ras_n),          //output O_ddr_ras_n
	.O_ddr_cas_n        (O_ddr_cas_n),          //output O_ddr_cas_n
	.O_ddr_we_n         (O_ddr_we_n),           //output O_ddr_we_n
	.O_ddr_clk          (O_ddr_clk),            //output O_ddr_clk
	.O_ddr_clk_n        (O_ddr_clk_n),          //output O_ddr_clk_n
	.O_ddr_cke          (O_ddr_cke),            //output O_ddr_cke
	.O_ddr_odt          (O_ddr_odt),            //output O_ddr_odt
	.O_ddr_reset_n      (O_ddr_reset_n),        //output O_ddr_reset_n
	.O_ddr_dqm          (O_ddr_dqm),            //output [1:0] O_ddr_dqm
	.IO_ddr_dq          (IO_ddr_dq),            //inout [15:0] IO_ddr_dq
	.IO_ddr_dqs         (IO_ddr_dqs),           //inout [1:0] IO_ddr_dqs
	.IO_ddr_dqs_n       (IO_ddr_dqs_n)          //inout [1:0] IO_ddr_dqs_n
);
    
endmodule
