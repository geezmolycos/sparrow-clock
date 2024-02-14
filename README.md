
# 麻雀时钟 / Sparrow Clock

[English Introduction](#english-introduction)

![](images/screenshot.png)

可以在悬浮窗中显示的模块化时钟，可以一键置顶或置底，自由调整位置，自由安排显示内容，基于 [LÖVE 引擎](https://love2d.org/)制作。

主要特点有：
- 符合我的个人审美
  - 也可以自己改成符合你审美的样子，但主要是我自己用，所以没有详细的文档，也不保证兼容旧版本
- 占用电脑资源很少
  - 画面刷新和事件响应分离，一秒刷新画面次数很少（默认小于10帧），占用CPU和GPU均极少
- 支持半透明显示
  - 使用 `DwmEnableBlurBehindWindow` 等 Windows API 让 LÖVE 的绘制内容透明叠加到桌面上
  - 目前只支持 Windows 系统，没有移植到其他系统的计划，但 LÖVE 兼容多系统，只要对应系统（或窗口合成器）上可以使用 lua ffi 调用 API 实现类似的效果，就可以移植。即使无法实现透明窗口，至少也可以在 LÖVE 支持的平台上运行
- 可以用 Lua 自己编写模块

## English Introduction

Modular clock within a floating window for effortless time-telling on your screen. Based on LÖVE and can be customized for your own need.

(No more because I'm tired at writing time to translate myself. Please use your favourite translator.)