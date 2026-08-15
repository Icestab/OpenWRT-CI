# OpenWRT-CI 红米AX6个人fork版本

基于 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI)，精简为仅保留红米AX6 (IPQ807X) 设备。删除其他平台配置及定时任务，手动触发编译。

# 源码

官方版：

https://github.com/immortalwrt/immortalwrt.git

自用版：

https://github.com/VIKINGYFY/immortalwrt.git

# U-BOOT

高通版-沉心：

https://github.com/chenxin527/uboot-qsdk12.5-build.git

高通版-小猪：

https://github.com/1980490718/u-boot-2016.git

# 本地编译

本地编译工具（PySide6 GUI，支持 Linux / WSL2）：

https://github.com/VIKINGYFY/OWRT-Tools.git

# 固件简要说明

仅编译红米AX6 (IPQ807X) 固件，手动触发。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

# 目录简要说明

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

#
[![Stargazers over time](https://starchart.cc/Icestab/OpenWRT-CI.svg?variant=adaptive)](https://starchart.cc/Icestab/OpenWRT-CI)
