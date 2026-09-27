# 第三方组件授权声明（THIRD_PARTY_LICENSES）

本项目（memo+）基于以下开源项目二次开发。**上游版权归各自作者所有**，本项目保留其全部版权声明与许可证文本。

---

## 一、主要上游项目

### 1. memoflow

- **用途**：应用基础架构、Flutter 客户端、笔记管理、编辑器、同步与附件体系
- **许可证**：**GNU General Public License v3.0**
- **版权**：归 memoflow 原作者及贡献者所有
- **本项目改动**：新增文档扫描、离线 OCR、批量重扫、本地标题生成；移除语音转写（详见 `发布声明.md` 第二节）
- **许可证文本**：见仓库根目录 `LICENSE`

> 因上游为 GPL-3.0，本项目整体同样以 GPL-3.0 发布。

### 2. OpenScan

- **用途**：文档边缘检测、透视矫正、图像滤镜等扫描核心算法
- **许可证**：**BSD 3-Clause License**
- **版权**：Copyright (c) 2021, Vijay T S and Vikram H
- **引入方式**：vendored（`third_party/openscan_cv`）
- **许可证文本**：见 `third_party/openscan_cv/LICENSE`

BSD-3-Clause 要求：保留版权声明、许可证文本，且不得使用作者名称为本项目推广背书。本项目遵循上述要求。

---

## 二、其他第三方组件

| 组件 | 用途 | 许可证 |
|---|---|---|
| Google ML Kit Text Recognition (Chinese) | 离线中文字符识别（bundled 模型） | Google APIs Terms of Service |
| phosphor_flutter（vendored，仅 Regular 字重） | 图标字体 | MIT |
| image_gallery_saver（vendored） | 图片保存到相册 | 见 `third_party/image_gallery_saver/LICENSE` |
| readability（vendored） | 正文抽取 | 见 `third_party/readability/LICENSE.md` |
| Flutter 及 pub 生态依赖 | 跨平台框架与各类工具库 | 各依其原许可证（见 `pubspec.yaml` / pub.dev） |

> 本构建基于上游 memoflow 的依赖集合（`pubspec.yaml`），未另行引入额外 copyleft 组件。
> 项目整体的 copyleft 义务来源为上游 memoflow（GPL-3.0）。

---

## 三、合规义务提醒（对本项目的下游使用者）

若你基于 memo+ 二次开发或分发，须遵守：

1. **提供完整源码**——不得仅分发 APK 而不提供源码
2. **保留全部上游版权声明**——包括 memoflow 与 OpenScan
3. **衍生作品同样以 GPL-3.0 发布**——不得改为闭源或其他不兼容许可证
4. **标注你的修改内容与日期**（参考本仓库 `修改说明.md`）
5. **不得附加额外限制**，妨碍下游用户行使 GPL-3.0 授予的权利

GPL-3.0 允许商业使用与收费，但上述开源义务**不因收费而豁免**。

---

_本文档为许可证信息说明，不构成法律意见。若涉及商业分发或合规审查，建议咨询专业法律人士。_
