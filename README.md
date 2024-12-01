<!--
 * @Author: Tomood
 * @Date: 2024-12-01 11:57:52
 * @LastEditors: Tomood
 * @LastEditTime: 2024-12-01 20:20:45
 * @FilePath: \Gowin-Tang-Primer-20K-DDR3-AXI-Stream-FIFO-Warpper\README.md
 * @Description: 
 * Copyright (c) 2024 by Tomood, All Rights Reserved. 
-->
# Gowin-Tang-Primer-20K-DDR3-AXI-Stream-FIFO-Warpper
This prj is a DDR3 AXI-Stream FIFO Warpper on Gowin Tang Primer 20K platform.
This warpper support axi stream interface that who can read and write like a normal asyn fifo.
For more detailed implementation principles and introduction, please see the code comments.
## How to start simulation?
### (1) use vcs
if you wanna use vcs to run simulation, just follow these steps:
```
cd $(Your repository PATH)/sim/run
make vcs
```
### (2) use modelsim
if you wanna use modelsim to run simulation, you need to add all files in **filelist.f** and **tb.sv** to your modelsim project manually.

## How to start a ddr test demo?
Not supported yet.

## Bug fix log:
2024.12.01: 修复了MIG IP返回读出数据时导致read侧fifo被写满的问题，增加了读取请求逻辑;完善了testbench代码，支持自动化verify