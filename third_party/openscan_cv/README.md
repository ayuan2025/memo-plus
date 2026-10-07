# openscan_cv

纯 Dart 的**文档边界检测、透视校正与扫描仪色彩滤镜**，取自
[OpenScan](https://github.com/ethereal-developers/OpenScan) Android 文档扫描 App，
并入 MemoFlow 供「扫描文档 → 存为 Memo 附件」链路使用。

本目录只保留**许可证与出处记录**；代码落在
`memos_flutter_app/lib/core/scan/`，与仓库既有的分层约定（`core` 层不得 import
`state` / `application` / `features`）保持一致。

## 出处

| 项 | 值 |
| --- | --- |
| 上游仓库 | `https://github.com/ethereal-developers/OpenScan` |
| 取用版本 | tag `v3.0.0`（2026-09-05） |
| 上游许可 | BSD 3-Clause，`Copyright (c) 2021, Vijay T S and Vikram H` |
| 许可证全文 | 同目录 [`LICENSE`](./LICENSE) |

上游 v3.0.0 把边缘检测与裁切从 OpenCV 改为**纯 Dart** 实现，因此可以在不引入
FFI、原生代码或 GMS 依赖的前提下被 Flutter 复用。BSD-3-Clause 与 MemoFlow 的
GPL-3.0 兼容，并入后保留原始版权声明即可。

## 取用的上游文件

| 上游路径 | 本地路径 | 说明 |
| --- | --- | --- |
| `lib/core/cv/models/point.dart` | `lib/core/scan/src/models/point.dart` | `Pt` 二维点 |
| `lib/core/cv/models/quad.dart` | `lib/core/scan/src/models/quad.dart` | `Quad` 四边形 |
| `lib/core/cv/models/detection_result.dart` | `lib/core/scan/src/models/detection_result.dart` | 检测结果三态 |
| `lib/core/cv/edge_detection.dart` | `lib/core/scan/src/edge_detection.dart` | 灰度/高斯/索贝尔/Otsu/膨胀 |
| `lib/core/cv/contours.dart` | `lib/core/scan/src/contours.dart` | 连通域、凸包、RDP、四点排序与打分 |
| `lib/core/cv/document_detector.dart` | `lib/core/scan/src/document_detector.dart` | 多阈值检测流水线 |
| `lib/core/cv/perspective_crop.dart` | `lib/core/scan/src/perspective_crop.dart` | 单应矩阵求解与双线性逆采样 |
| `lib/core/cv/compress.dart` | `lib/core/scan/src/page_renderer.dart` | 长边限制与 JPEG 编码 |
| `lib/core/cv/capture_pipeline.dart` | `lib/core/scan/src/page_renderer.dart` | 「一次解码完成裁切+缩放+编码」 |
| `lib/core/image_filter/filters/filters.dart` | `lib/core/scan/src/filters/filter.dart` | `Filter` 基类 |
| `lib/core/image_filter/filters/document_filters.dart` | `lib/core/scan/src/filters/document_filters.dart` | 六种文档色彩模式 |
| `lib/core/image_filter/utils/image_filter_utils.dart` | `lib/core/scan/src/filters/filter_pixels.dart` | 饱和度/灰度/对比度 |
| `lib/core/image_filter/utils/document_filter_utils.dart` | `lib/core/scan/src/filters/filter_field_utils.dart` | 积分图、盒式模糊、直方图、LUT |
| `lib/core/image_filter/apply_filter.dart` | `lib/core/scan/src/filters/apply_filter.dart` | 滤镜应用与编码 |

上游的 `lib/core/cv/native_decode.dart`（`dart:ui` 平台解码加速）与
`lib/core/cv/frame_adapter.dart`（相机实时帧转灰度）**未取用**：前者依赖
`dart:ui` 编解码器，后者依赖 `camera_platform_interface` 的帧格式约定，二者都
是 OpenScan 实时取景架构的产物，与 MemoFlow 的一次性拍摄流程无关。

## 本地改动

本地改动均为**去除 I/O 与平台耦合**，算法本身逐行保持上游实现：

1. **文件 I/O 移除，改为 byte-in / byte-out**。上游入口点形如
   `cropImageIsolateEntry(Map<String, dynamic> params)`，内部读 `params['path']`
   并经 `File` 覆写原文件；本仓库改为 `cropToQuadBytes(Uint8List, Quad)`、
   `renderScannedPage(Uint8List, quad: ...)`、`filterDocumentBytes(...)`，只接受与
   返回编码后的字节。这样 `dart:io` 不再进入调用链，既能在 `compute()` 隔离区
   运行，也不阻断 Web 构建。
2. **`compress.dart` + `capture_pipeline.dart` 合并为 `page_renderer.dart`**。
   上游把「裁切 / 缩放到页面尺寸 / 保留原图」拆成多个隔离区入口，各自解码一次；
   本地合并为**一次解码**完成「裁切 → 长边限制 → JPEG 编码」，并把解码失败时的
   原样透传语义（`decoded: false`）保留下来。
3. **`CropResult` 从 `models/detection_result.dart` 移到 `perspective_crop.dart`**，
   `DetectionResult` 由 `abstract class` 改为 `sealed class`，以便调用方用穷尽
   `switch` 处理三态结果。
4. **`Filter` 子类改为 `const` 构造**，滤镜清单改为 `const List<Filter>`。
5. **注释与文档改写**为 MemoFlow 语境（英文），删去指向 OpenScan 自身 UI、数据库
   与 `compute()` 入口的交叉引用。每个文件头部标注了上游出处与许可。
6. **`corner_refinement.dart` / `quad_smoothing.dart` / `ocr_preprocess.dart` /
   `full_frame_page.dart` 为本地新增**（上游无对应实现）：

   * `corner_refinement.dart` —— 上游只用 RDP 简化轮廓，角点落在轮廓弯折处而非
     纸张真正的转角；本地版对四条边逐点重拟合后再求交点。
   * `quad_smoothing.dart` —— 实时预览的帧间 EMA 平滑与丢帧保持。
   * `ocr_preprocess.dart` —— OCR 输入的分档预处理（去光照 / 自动色阶）。
   * `full_frame_page.dart` —— **判断输入本身是否已经是一整页**（相册导入、
     截图、别处裁剪过的图）。上游假设输入总是「（纸张 + 背景）的照片」，
     对已满裁的输入会把画面内部的某个方框当成纸张边而裁掉页面其余部分。
     相应地，`DetectionSuccess` / `DetectionNotFound` 增加了 `fullPageReason`
     字段，`document_detector.dart` 在返回前多跑一次 Sobel 用于该判定。

## 使用

```dart
import 'package:memos_flutter_app/core/scan/document_scan.dart';

// 1. 检测边界（可放进 compute()，不抛异常）
final DetectionResult detected = detectDocumentInBytes(capturedBytes);
final Quad? quad = detected is DetectionSuccess ? detected.quad : null;

// 2. 校正 + 缩放 + 编码，一次解码
final page = renderScannedPage(capturedBytes, quad: quad);

// 3. 可选：套用扫描仪色彩模式
final filtered = filterDocumentBytes(page.bytes, filterName: 'Auto');
```

## 测试

单元测试位于 `memos_flutter_app/test/scan/`，随主工程 `flutter test` 一起运行，
不需要单独的 `pub get`。
