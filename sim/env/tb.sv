/*
 * @Author: Tomood
 * @Date: 2024-11-19 19:35:13
 * @LastEditors: Tomood
 * @LastEditTime: 2024-12-01 11:51:07
 * @FilePath: \gowin_ddr_rw_demo\sim\env\tb.sv
 * @Description: ddr3 sdram sim top
 * Copyright (c) 2024 by Tomood, All Rights Reserved. 
 */

`timescale 1ns / 1ps

module tb;

    parameter CLK_PERIOD = 40;//ns
    parameter CLK_HIGH   = CLK_PERIOD / 2;
    parameter CLK_LOW    = CLK_PERIOD / 2;

    `define SIM_TIME 2.5ms

    // Inouts
    wire[15:0]      ddr3_dq     ;
    wire[1:0]       ddr3_dqs_n  ;
    wire[1:0]       ddr3_dqs_p  ;
    // Outputs
    wire [12:0]     ddr3_addr   ;
    wire [2:0]      ddr3_ba     ;
    wire            ddr3_ras_n  ;
    wire            ddr3_cas_n  ;
    wire            ddr3_we_n   ;
    wire            ddr3_reset_n;
    wire [0:0]      ddr3_ck_p   ;
    wire [0:0]      ddr3_ck_n   ;
    wire [0:0]      ddr3_cke    ;
    wire [0:0]      ddr3_cs_n   ;
    wire [1:0]      ddr3_dm     ;
    wire [0:0]      ddr3_odt    ;

reg         s_axis_aclk    = 0;
wire        s_axis_tready ;
reg         s_axis_tvaild  = 0;
reg [15:0]  s_axis_tdata   = 0;

reg         m_axis_aclk   = 0 ;
reg         m_axis_tready = 0 ;
wire        m_axis_tvaild     ;
wire [15:0] m_axis_tdata      ;   

GSR GSR(.GSRI(1'b1));

wire init_calib_complete;

    //sys
    bit m_axis_aclk = 1;
    bit s_axis_aclk = 1;
    bit osc_clk = 1;
    bit sys_rst_n = 1;

    initial begin
        #2400000ps;
        sys_rst_n = 0;
        #480000ps;
        sys_rst_n = 1'b1;
    end 

    initial  begin
        forever begin
            osc_clk = 1;
            #CLK_HIGH;
            osc_clk = 0;
            #CLK_LOW;
        end
    end

    initial  begin
        forever begin
            fork
                m_axis_aclk = #50 ~m_axis_aclk;
                s_axis_aclk = #50 ~s_axis_aclk;
            join
        end
    end

    initial begin
        #`SIM_TIME;
        $display("[T=%t] -INFO- TIMEOUT simulation finished.\n",$time);  
        $finish;
    end

    //for verdi
    initial begin
    @(posedge init_calib_complete)//从初始化成功开始dump波形
    $fsdbDumpfile("test.fsdb");
    $fsdbDumpvars(3);
    $fsdbDumpMDA();
    end

// ddr3_rw_controller Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;


//写通道控制逻辑
initial begin
    @(posedge init_calib_complete)//等待初始化成功
    #10000;
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    #10000;
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    #10000;
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    #10000;
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    #10000;
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    #10000;
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    master_axis_wrdat($urandom);
    #100us;
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    #100;
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    slave_axis_rddat();
    #100us;
    $finish;
end

//仿真模型
ddr3_model u_ddr3_model (
    .rst_n   (ddr3_reset_n ),
    .ck      (ddr3_ck_p    ),
    .ck_n    (ddr3_ck_n    ),
    .cke     (ddr3_cke     ),
    .cs_n    (ddr3_cs_n    ),
    .ras_n   (ddr3_ras_n   ),
    .cas_n   (ddr3_cas_n   ),
    .we_n    (ddr3_we_n    ),
    .dm_tdqs (ddr3_dm      ),
    .ba      (ddr3_ba      ),
    .addr    (ddr3_addr    ),
    .dq      (ddr3_dq      ),
    .dqs     (ddr3_dqs_p   ),
    .dqs_n   (ddr3_dqs_n   ),
    .tdqs_n  (),
    .odt     (ddr3_odt     )
);




//dut
ddr3_rw_controller  u_ddr3_rw_controller (
    //sys input
    .clk                     ( osc_clk                     ),
    .rst_n                   ( sys_rst_n                   ),
    .init_calib_complete     (init_calib_complete), //ddr ip init done
    //usr fifo interface wr (axis slave)
	.s_axis_aclk             (s_axis_aclk),       // fifo wr_clk
	.s_axis_tready           (s_axis_tready),       // axi slave ready
	.s_axis_tvaild           (s_axis_tvaild),       // axi master vaild(fifo wr_en)
	.s_axis_tdata            (s_axis_tdata),       // fifo wr_data
	//usr fifo interface rd (axis master)
	.m_axis_aclk             (m_axis_aclk),       // fifo rd_clk
	.m_axis_tready           (m_axis_tready),       // axi slave ready(fifo rd_en)
	.m_axis_tvaild           (m_axis_tvaild),       // axi master vaild
	.m_axis_tdata            (m_axis_tdata),       // fifo wr_data
    //ddr3 interface
    .O_ddr_addr              ( ddr3_addr                   ),
    .O_ddr_ba                ( ddr3_ba                     ),
    .O_ddr_cs_n              ( ddr3_cs_n                   ),
    .O_ddr_ras_n             ( ddr3_ras_n                  ),
    .O_ddr_cas_n             ( ddr3_cas_n                  ),
    .O_ddr_we_n              ( ddr3_we_n                   ),
    .O_ddr_clk               ( ddr3_ck_p                   ),
    .O_ddr_clk_n             ( ddr3_ck_n                   ),
    .O_ddr_cke               ( ddr3_cke                    ),
    .O_ddr_odt               ( ddr3_odt                    ),
    .O_ddr_reset_n           ( ddr3_reset_n                ),
    .O_ddr_dqm               ( ddr3_dm                     ),
    .IO_ddr_dq               ( ddr3_dq                     ),
    .IO_ddr_dqs              ( ddr3_dqs_p                  ),
    .IO_ddr_dqs_n            ( ddr3_dqs_n                  )
);

task master_axis_wrdat(input [15:0] wrdata);
    @(posedge s_axis_aclk)
    wait(s_axis_tready == 1'b1);
    s_axis_tvaild = 1'b1;
    s_axis_tdata = wrdata;
    @(posedge s_axis_aclk)
    s_axis_tvaild = 1'b0;
    $display("[T=%t] -INFO- master_axis_wrdat: 16'h%0x",$time,wrdata);
endtask

task slave_axis_rddat();
    bit [15:0] rddata;
    @(posedge m_axis_aclk)
    wait(m_axis_tvaild == 1'b1)
    m_axis_tready = 1'b1;
    @(posedge s_axis_aclk)
    rddata = m_axis_tdata;
    m_axis_tready = 1'b0;
    $display("[T=%t] -INFO- slave_axis_rddat: 16'h%0x",$time,rddata);
endtask


endmodule
