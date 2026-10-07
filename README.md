# memo+

memo+ 是一款本地优先的笔记客户端，基于开源项目 [MemoFlow](https://github.com/hzc073/memoflow)（GPL-3.0）深度改进而来，兼容 [Memos](https://github.com/usememos/memos) 服务器协议。

在 MemoFlow 的记录、标签、集合、回顾等基础能力之上，memo+ 重点强化了：

- **文档扫描**：拍照或导入图片 → 自动检测纸张边界 → 透视校正 → 扫描仪色彩滤镜 → 存为笔记附件，全程离线；支持满页智能判定、批量重扫与页内旋转。
- **文字识别（OCR）**：扫描件内置 ML Kit 离线文字识别，可全文检索扫描内容，不上传任何图片。
- **笔记卡片导出**：把一条笔记渲染成可分享的纸面卡片并导出为图片，内置暖白纸感、深夜便签、备忘录深浅色等多套主题（设计取自开源的锤子便签复刻项目 [zhaoolee/notes](https://github.com/zhaoolee/notes)）。
- **本地优先**：无账号、无遥测；数据完全存放在本机，可选同步到自建 Memos 服务器，可选 WebDAV 备份（加密）。
- **桌面端**：Windows / macOS 桌面形态，快捷输入、托盘、多窗口。

## 下载安装

前往 [Releases](../../releases) 页面下载最新的 APK（Android，arm64）安装。

应用内「设置 → 关于 → 检查更新」会从本仓库的 Releases 读取 `latest.json` 提示新版本。发布新版本时，把 `latest.json`（含各语言副本 `latest.<locale>.json`）与 APK 一起作为 Release 附件上传即可，`releases/latest/download/` 地址永远指向最新一版。

## 版权与致谢

memo+ 由多个开源项目组成，主要来源：

| 项目 | 许可证 | 用途 |
| --- | --- | --- |
| [MemoFlow](https://github.com/hzc073/memoflow) | GPL-3.0 | 应用基底，memo+ 是其衍生作品 |
| [OpenScan](https://github.com/ethereal-developers/OpenScan) | BSD-3-Clause | 文档扫描引擎（边界检测 / 透视校正 / 色彩滤镜） |
| [zhaoolee/notes](https://github.com/zhaoolee/notes) | Apache-2.0 | 锤子便签风格的笔记卡片主题（导出图片 / 模板） |

完整第三方组件清单（含 libcaesium、image_gallery_saver、phosphor_flutter、Readability.js 等）见 [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)。

## 许可证

本项目基于 MemoFlow 衍生，依 GPL-3.0 以同许可证发布。完整许可证文本见 [LICENSE](./LICENSE)。

分发本软件时须遵守 GPL-3.0：保留上游版权声明、标明修改、并提供对应源码。
