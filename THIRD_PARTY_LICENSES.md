# 第三方组件与许可证声明（THIRD PARTY NOTICES）

memo+ 由多个开源项目组成。本文件列出所有进入发行包的第三方代码/素材及其许可证。各组件的版权与许可原文归各自作者所有；本仓库按其条款引用。

## 主要组成部分

### 1. MemoFlow — 应用基底（GPL-3.0）

- 上游仓库：<https://github.com/hzc073/memoflow>
- 许可证：GNU General Public License v3.0（见仓库根目录 [LICENSE](./LICENSE)）
- 说明：memo+ 的界面、数据模型、同步、备份、迁移等主体代码衍生自 MemoFlow。memo+ 作为其衍生作品按 GPL-3.0 以同许可证发布，保留上游版权声明；相对上游的修改以源码形式随本仓库公开。
- 保留的上游标识：备份格式（`MemoFlowVault` / `MemoFlowBackup`、`/MemoFlow/settings/v1` 路径）、局域网迁移 Bonjour 服务名（`_memoflow._tcp` 等）与包名（`com.memoflow.*`）为保证兼容性而原样保留，属于协议标识，不代表品牌。

### 2. OpenScan — 文档扫描引擎（BSD-3-Clause）

- 上游仓库：<https://github.com/ethereal-developers/OpenScan>（取用 tag `v3.0.0`）
- 上游版权：Copyright (c) 2021, Vijay T S and Vikram H
- 许可证全文：[third_party/openscan_cv/LICENSE](./third_party/openscan_cv/LICENSE)
- 取用内容：文档边界检测、透视校正、扫描仪色彩滤镜（纯 Dart 实现），落在 `lib/core/scan/`；逐文件的出处与改动记录见 [third_party/openscan_cv/README.md](./third_party/openscan_cv/README.md)。

### 3. zhaoolee/notes — 锤子便签风格卡片主题（Apache-2.0）

- 上游仓库：<https://github.com/zhaoolee/notes>（复刻锤子便签的开源 Web 应用）
- 许可证：Apache License 2.0
- 取用内容：`src/lib/note-card-theme-styles.ts` 中的卡片主题设计令牌（配色、纸面、字体栈），1:1 移植为 `lib/features/memos/theme/memo_card_theme.dart`，用于「笔记导出为图片」的分享卡片与模板样式。第三方产品名主题（Bear 等）已改为中性名称。

## 其他组件

| 组件 | 许可证 | 版权 | 在本仓库的位置 | 用途 |
| --- | --- | --- | --- | --- |
| libcaesium 0.17.4 | Apache-2.0 | Copyright Matteo Paonessa | 预编译产物（见 `third_party/libcaesium/README.md`） | 图片压缩（FFI） |
| image_gallery_saver | MIT | Copyright (c) 2023 zaihui | `third_party/image_gallery_saver/` | 保存图片到系统相册 |
| phosphor_flutter | MIT | Copyright (c) 2020-2021 Phosphor Icons | `third_party/phosphor_flutter/` | 图标字体 |
| Readability.js | Apache-2.0 | Copyright (c) 2010 Arc90 Inc | `third_party/readability/` | 网页正文提取 |

## 运行时依赖说明

- **Google ML Kit 文字识别**（`google_mlkit_text_recognition`）：设备端离线推理，不联网上传；作为系统组件随 Google Play services 分发（或随 APK 内置模型）。
- **Memos 服务端**（[usememos/memos](https://github.com/usememos/memos)）：memo+ 通过其 HTTP API 与自建 Memos 服务器通信，但**不捆绑**其代码，故不构成衍生。
