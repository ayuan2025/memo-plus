// 本地补充的图像算子：可分离盒状模糊。
//
// 纯 Dart、操作扁平字节缓冲、可丢进 isolate 单测。供边界检测的粗尺度梯度
// 场（见 `edge_detection.dart` 的 `documentEdgeMagnitude`）使用。
//
// 与 `ocr_preprocess.dart` 里的私有 `_boxBlurGray` 是同一套算法，但那份的
// 归一化方式不同（按实际落入窗口的样本数平均，本份按固定窗口宽度平均）。
// 边界检测必须用本份：它的半径是画幅长边的 0.8%，是**调过的**参数，配套的
// 归一化方式不能换——改了等于把标定过的检测器挪了位置。

import 'dart:typed_data';

/// 单通道灰度缓冲的可分离盒状模糊（先横后竖），滑动窗口求和版。
///
/// [radius] 为半窗宽，0 表示不模糊（原样返回拷贝）。边缘用 clamp 重复采样，
/// 一点模糊容差无所谓。
///
/// 复杂度与核半径无关（每像素 O(1)，窗口求和滑动推进），所以
/// `documentEdgeMagnitude` 里那种几十像素的大半径也不卡。
Uint8List boxBlurGray(Uint8List src, int width, int height, int radius) {
  final r = radius.clamp(0, width > height ? width : height);
  if (r <= 0) return Uint8List.fromList(src);

  final window = 2 * r + 1;
  final temp = Uint8List(width * height);

  // 横向。
  for (var y = 0; y < height; y++) {
    var sum = 0;
    for (var x = -r; x <= r; x++) {
      sum += src[y * width + x.clamp(0, width - 1)];
    }
    for (var x = 0; x < width; x++) {
      temp[y * width + x] = (sum / window).round().clamp(0, 255);
      final xOut = (x - r).clamp(0, width - 1);
      final xIn = (x + r + 1).clamp(0, width - 1);
      sum += src[y * width + xIn] - src[y * width + xOut];
    }
  }

  // 纵向。
  final out = Uint8List(width * height);
  for (var x = 0; x < width; x++) {
    var sum = 0;
    for (var y = -r; y <= r; y++) {
      sum += temp[(y.clamp(0, height - 1)) * width + x];
    }
    for (var y = 0; y < height; y++) {
      out[y * width + x] = (sum / window).round().clamp(0, 255);
      final yOut = (y - r).clamp(0, height - 1);
      final yIn = (y + r + 1).clamp(0, height - 1);
      sum += temp[yIn * width + x] - temp[yOut * width + x];
    }
  }
  return out;
}
