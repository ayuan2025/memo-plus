# memo+

> 基于 [memoflow](https://github.com/memoflow/memoflow)（**GPL-3.0**）与 OpenScan（**BSD-3-Clause**）二次开发的安卓笔记应用：
> **文档扫描 + 离线 OCR + 笔记管理 + 同步**。

拍一张纸质材料，自动找边、透视矫正、增强，离线 OCR 出中文，文字进笔记可被搜索——
扫描、识别、归档全在本机完成，页面不出设备。

---

## 许可证

**本项目以 GNU General Public License v3.0（GPL-3.0）发布。**

memo+ 是 memoflow 的衍生作品。依 GPL-3.0 第 3 条，分发目标代码（APK）时必须同时提供
对应源码——本仓库即源码，发布 APK 时源码随仓库/Release 一同公开。

任何基于 memo+ 的衍生作品，**必须同样以 GPL-3.0 开源**，且不得附加限制。

| 文件 | 内容 |
|---|---|
| `LICENSE` | GPL-3.0 完整文本 |
| `THIRD_PARTY_LICENSES.md` | 第三方组件授权明细 |
| `发布声明.md` | 源码来源、上游致谢、改动说明、使用场景 |

---

## 功能（v1.0.49）

- **文档扫描**：相机 / 相册入口，自动选边（描边检测）+ 透视矫正 + 多页导出；相机锁 AF/AE、长按对焦
- **离线 OCR**：Google ML Kit 中文模型（bundled，不依赖 Google Play 服务），全程本机，无网也能用
  - 识别到的文字以**隐藏正文**写入笔记，可被全文搜索，但不在编辑区显示
  - 多档图像预处理（含原图兜底），取识别字符数最长的一档，提高准确率
- **扫描件增强**：默认套 Auto 滤镜；支持**批量重扫**（设置 → 导入导出 → 重新识别扫描件）
- **笔记管理与同步**：笔记、附件、同步沿用 memoflow 原有能力（含服务器 / WebDAV 同步）
- **语音便签**：原版纯录音（只存音频、不转文字），**不依赖 Google 语音服务**，无网也能录

> v1.0.49 相较上游移除了「语音转写」这一实验性功能，录音恢复为官方原版行为。

---

## 下载

GitHub Releases 提供已构建 APK：

- 标签：`v1.0.49`
- 架构：`arm64-v8a`（安卓）
- 签名：✅ **发布签名（Release keystore）**

> **升级提示**：本版本起改用发布签名。若你之前装过 Debug 签名版本（1.0.48/1.0.49 调试包），
> 两者签名不同，**需先卸载旧版再安装**（数据会被清空）。全新安装不受影响，后续更新可覆盖安装。

---

## 从源码构建

仓库根目录即 Flutter 应用根（含 `pubspec.yaml`）。

```bash
git clone <本仓库地址>
cd <仓库根目录>
flutter pub get
flutter build apk --release --flavor full --target-platform android-arm64
```

环境要求：Flutter 3.x / Dart 3.x、JDK 17、Android SDK（compileSdk 36）。

如需自行签名，在 `android/key.properties` 填入你的签名信息（注意该文件已被 `.gitignore` 排除，切勿提交）。

---

## 上游致谢

- **memoflow** — 应用骨架与笔记能力（GPL-3.0）
- **OpenScan** — 文档扫描与图像处理核心算法（BSD-3-Clause，Copyright (c) 2021, Vijay T S and Vikram H）

本项目仅对新增的扫描、离线 OCR、本地标题生成、批量重扫等部分主张工作成果；
其余笔记管理、同步、编辑器等基础能力均为上游 memoflow 原有实现，版权归其原作者。

---

## 免责声明

本项目为个人二次开发，**非成熟商业产品**，按"现状"提供，不提供担保，亦不保证适销性或特定用途适用性。
敏感材料请自行评估风险。
