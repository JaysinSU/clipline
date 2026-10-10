# 晾图 Clipline

用飞书截图后，图片自动挂到屏幕顶部的绳子上。按 **Option + Q** 随时展开或收起，全屏时也可以手动呼出。

基于 [Tendedero](https://github.com/alejandrobujan/tendedero) 的开源增强版，使用独立名称、图标与设置。支持 macOS 14 及以上，Apple 芯片与 Intel Mac。

[下载最新版本](https://github.com/JaysinSU/clipline/releases/latest) · [English](docs/README.en.md) · [更新记录](CHANGELOG.md)

## 安装

1. 打开 [Releases](https://github.com/JaysinSU/clipline/releases/latest)，下载 `Clipline-1.1.2.zip`。只想使用应用，下载这个文件即可。
2. 解压，将 `Clipline.app` 拖入「应用程序」文件夹。
3. 如在使用原版 Tendedero，先退出原版，再启动 Clipline。菜单栏会出现衣服图标。
4. 默认开启“接收剪贴板图片（飞书截图）”。用飞书截图，点击“完成/复制”，让截图进入剪贴板，图片会自动挂上绳子。

此版本采用本地 ad-hoc 签名，尚未通过 Apple 公证。首次打开若被 macOS 拦截，请确认文件来自本仓库，再按 [Apple 的打开说明](https://support.apple.com/zh-cn/102445) 在「系统设置 → 隐私与安全性」中授权打开。

完整源码可从本仓库下载；发布页的 `Clipline-1.1.2-source.zip` 包含源码、构建脚本、测试、说明和许可。`Clipline-1.1.2-all.zip` 同时包含应用与完整源码。`SHA256SUMS.txt` 提供这些文件的校验值。

## 使用

| 操作 | 结果 |
| --- | --- |
| 飞书截图后点击“完成/复制” | 新图片自动挂上绳子 |
| Option + Q | 展开或收起绳子，全屏时也可用 |
| 指针移到菜单栏 | 在普通桌面展开绳子 |
| 菜单栏 → 显示晾衣绳 | 手动展开绳子 |
| 单击图片 | 复制图片 |
| 长按图片 | 打开标记 |
| 双击图片 | 打开预览 |
| 拖到应用 | 分享图片副本 |
| 拖到文件夹 | 保存图片并从绳上取下 |
| 点击图片左上角的叉 | 将应用管理的图片移到废纸篓 |

全屏时，收到新截图或鼠标悬停不会自动展开绳子。使用 **Option + Q** 或菜单手动呼出；再次按快捷键可收起。访问图片后移开鼠标也会自动收起。截图仍会保存在绳上。

“接管截图”用于管理 macOS 系统截图，可按需开启；飞书剪贴板接收不依赖该选项。开启后，应用会保存并修改系统截图位置和浮动缩略图设置；关闭该选项或正常退出应用时恢复原设置。

## 接收范围与数据

应用接收各应用新写入剪贴板的 PNG、TIFF、JPEG、HEIC、WebP 图片，因此复制其他应用的图片也可能挂上。飞书必须把截图写入系统剪贴板；仅在飞书内部发送、未复制的图片无法接收。本项目通过公开的 macOS 剪贴板格式工作，没有使用飞书私有接口。

文本、单纯复制的文件路径、启动前已有的剪贴板图片，以及标记为私密或临时的剪贴板数据会被跳过。相同像素的图片会去重，点击绳上图片复制不会产生重复图片。

每 0.2 秒检查一次剪贴板变更，图片转换和绘制还需要少量时间。接收时保持剪贴板原内容，可继续粘贴到聊天等应用。多显示器时，图片挂到指针所在的屏幕。

图片以完整分辨率 PNG 保存在 `~/Library/Application Support/Clipline/Clipboard`，重启后可恢复。菜单中的“打开剪贴板图片文件夹”可查看保存位置。应用不包含联网请求，不上传截图。复制其他应用的图片也会保存到本地；可在菜单中关闭接收开关。

## 从源码构建

需要 macOS 14 及以上和 Xcode Command Line Tools。应用使用 Swift、AppKit 与 SwiftUI，没有第三方包依赖。

```bash
git clone https://github.com/JaysinSU/clipline.git
cd clipline
bash scripts/build-app.sh
open build/Clipline.app
```

构建脚本生成同时支持 Apple 芯片与 Intel 的通用应用包。默认使用 ad-hoc 签名；有 Developer ID 时，可通过 `SIGN_IDENTITY` 指定签名身份。构建脚本不会自动提交 Apple 公证。

```bash
bash scripts/test-clipboard.sh
bash scripts/test-fullscreen.sh
swift scripts/check-strings.swift
bash scripts/package-release.sh
```

剪贴板测试使用独立命名剪贴板，不覆盖日常剪贴板。全屏测试会短暂打开空白全屏窗口，验证手动展开与收起后自动关闭。打包结果保存在 `build/releases`。

1.1.2 的应用已构建为通用二进制并通过签名校验。剪贴板集成测试 15/15 项通过，原生全屏测试 9/9 项通过，28 条界面文案均有中、英、西语翻译。构建环境为 Swift 6.2.4 / macOS 26.2 SDK。

## 反馈与贡献

通过 [Issues](https://github.com/JaysinSU/clipline/issues) 反馈问题或建议，请注明应用版本、macOS 版本、截图方式与复现步骤。提交截图前请移除私人信息。欢迎通过 Pull Request 贡献代码和翻译。

## 来源与许可

截图挂绳交互、绘制和基础代码来自 Alejandro Buján 的 [Tendedero](https://github.com/alejandrobujan/tendedero)，上游基线为 `ed0618a67cc59e0a8621b97bb5e32ab9af3b0b69`。原版权声明和完整许可保留在 [LICENSE](LICENSE)，应用包也包含许可。

源码采用 MIT 许可。原项目的名称与图标不在其 MIT 授权范围内，因此本项目更换为 Clipline 名称及原创剪贴板图标，也不分发上游文档中的品牌图片。本项目不代表原作者或飞书官方背书。
