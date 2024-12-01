`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/03 22:00:25
// Design Name: 
// Module Name: ddr3_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ddr3_sim;

    parameter APP_DATA_WIDTH 	= 128 ;
    parameter APP_ADDR_WIDTH    = 28  ;
    parameter BURST_LEN         = 64  ;

    reg   i_sys_clk_50m = 0;
    reg   i_sys_rst_n   = 0;


    // Inouts
    wire[15:0]      ddr3_dq     ;
    wire[1:0]       ddr3_dqs_n  ;
    wire[1:0]       ddr3_dqs_p  ;
    // Outputs
    wire [13:0]     ddr3_addr   ;
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


    reg [(8*20)-1:0] r_sim_st_burst = "??UNKNOWN??";

    //����ģ��
    ddr3_model ddr3_model_inst (
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

    prj_ddr_top prj_ddr_top_inst(
       .i_sys_clk_50m      (i_sys_clk_50m),
       .i_sys_rst_n        (i_sys_rst_n  ),
       // Inouts
       .ddr3_dq            (ddr3_dq   ),
       .ddr3_dqs_n         (ddr3_dqs_n),
       .ddr3_dqs_p         (ddr3_dqs_p),
       // Outputs
       .ddr3_addr          (ddr3_addr   ),
       .ddr3_ba            (ddr3_ba     ),
       .ddr3_ras_n         (ddr3_ras_n  ),
       .ddr3_cas_n         (ddr3_cas_n  ),
       .ddr3_we_n          (ddr3_we_n   ),
       .ddr3_reset_n       (ddr3_reset_n),
       .ddr3_ck_p          (ddr3_ck_p   ),
       .ddr3_ck_n          (ddr3_ck_n   ),
       .ddr3_cke           (ddr3_cke    ),
       .ddr3_cs_n          (ddr3_cs_n   ),
       .ddr3_dm            (ddr3_dm     ),
       .ddr3_odt           (ddr3_odt    )
   );

    always @(prj_ddr_top_inst.ddr_burst_top_inst.ddr_mc_burst_inst.r_st_rd_wr) begin
        case (prj_ddr_top_inst.ddr_burst_top_inst.ddr_mc_burst_inst.r_st_rd_wr)
            6'b00_0001 : begin $display("%t: STATE is now: ST_BURST_IDEL 	", $realtime); r_sim_st_burst = "ST_BURST_IDEL 	  "; end
            6'b00_0010 : begin $display("%t: STATE is now: ST_BURST_WR_CMD  ", $realtime); r_sim_st_burst = "ST_BURST_WR_CMD  "; end
            6'b00_0100 : begin $display("%t: STATE is now: ST_BURST_RD_CMD  ", $realtime); r_sim_st_burst = "ST_BURST_RD_CMD  "; end
            6'b00_1000 : begin $display("%t: STATE is now: ST_BURST_DONE_W 	", $realtime); r_sim_st_burst = "ST_BURST_DONE_W  "; end
            6'b01_0000 : begin $display("%t: STATE is now: ST_BURST_DONE 	", $realtime); r_sim_st_burst = "ST_BURST_DONE 	  "; end
            6'b10_0000 : begin $display("%t: STATE is now: ST_BURST_DONE2 	", $realtime); r_sim_st_burst = "ST_BURST_DONE2   "; end
          default : begin $display("%t: ERROR: STATE is now: UNKNOWN !!!!", $realtime); r_sim_st_burst = "??UNKNOWN??";end
        endcase
    end

    initial  begin 
        #500;
        i_sys_rst_n = 1'b1;
    end 

    always #10 i_sys_clk_50m = ~i_sys_clk_50m;


endmodule
