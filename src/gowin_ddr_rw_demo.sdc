//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10 (64-bit) 
//Created Time: 2024-12-01 12:02:09
create_clock -name osc_clk -period 37.037 -waveform {0 18.518} [get_ports {clk}] -add
create_clock -name ddr_mem_clk -period 2.5 -waveform {0 1.25} [get_nets {memory_clk}] -add
