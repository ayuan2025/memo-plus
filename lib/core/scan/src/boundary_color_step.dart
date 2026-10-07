// 本地补充的边界证据：这个矩形到底有没有把两个区域分开？
//
// 检测器给出的「最佳矩形」有两种来路完全不同的错法，都会让用户真的被裁掉
// 内容，而这两种错法都躲得过基于梯度强度的检查：
//
//  * 框住了纸张内部的一整块东西（一段文字、一个表格、一个印章），它的四周
//    仍然在纸上 —— 于是四周的梯度并不弱，而框本身看着也很方正；
//  * 框是背景纹理拼出来的，压根没有对应的实体边界。
//
// 两者的共同特征是：**框的两侧其实是同一种东西**。真正的纸边两侧必然是纸和
// 纸以外的东西，颜色（而不只是亮度）一定不同。所以判据直接照着这句话写：
// 沿四条边取内侧一条带和外侧一条带，比较两带的平均颜色；差得太小就说明这个
// 框不是纸边。
//
// 这条判据只用来「降级」——判不过就退回不裁，绝不主动裁。所以它错判的代价是
// 少裁一次，而不是裁错。

import 'dart:math';
import 'dart:typed_data';

import 'models/quad.dart';

/// 判定一条边是「区域边界」所需的最小颜色落差（Y/Cb/Cr 空间的距离）。
///
/// 取值是拿实拍样张标定的（在原始分辨率上、用本函数实现量）：判对了的检测
/// 框落差 16.3~141.2。取 16 压着好例的下缘，并且偏向「宁可判不过」那一侧
/// —— 判不过只是不裁，判过了才会裁错。
///
/// 口径很重要：这些数是在**原始分辨率**上量的。内外带宽度是画幅对角线的固定
/// 比例，分辨率变了带宽就跟着变、数值也跟着变 —— 同一个框在 ~700px 的工作
/// 缓冲上量会明显偏高（黑字行恰好卡在窄带里，把「字 vs 纸」的落差撑过阈值），
/// 而在原始分辨率上量才会露出它的真面目。调用方必须在原始分辨率上调用。
///
/// 也要诚实面对这个判据的边界：它拦得住「两侧是同一种东西」的框（框住空白、
/// 框住背景纹理拼出来的假矩形），拦不住「框住一段文字」—— 文字与纸的颜色
/// 差比弱纸边还大，只是断断续续。后者目前交给整页守卫（框外还有纸的其余部
/// 分）去拦，拦不住的就是已知局限。
///
/// 注意这不是亮度阈值，是颜色距离：一张浅灰便签放在白桌面上，亮度只差几个
/// 数，色度差却可能推高到 20 以上，这正是只有亮度时看不见、加上颜色才看得见
/// 的那类边界。
const double kMinBoundaryColorStep = 16.0;

/// 沿 [quad] 四条边，量内侧带与外侧带之间的平均颜色差（Y/Cb/Cr 距离）。
///
/// 内侧带从 [innerFraction] 起、到 [outerFraction] 止（以画幅对角线为基准），
/// 外侧带同样距离、方向相反，两带都不贴边，避开边界两侧的抗锯齿过渡像素。
///
/// 返回 0~255 量级的距离：两个区域颜色不同就大，同一种东西的两半就接近 0。
double boundaryColorStep(
  Uint8List rgba,
  int width,
  int height,
  Quad quad, {
  double innerFraction = 0.012,
  double outerFraction = 0.030,
}) {
  if (width <= 0 || height <= 0) return 0;
  if (rgba.length < width * height * 4) return 0;

  final diagonal = sqrt(width * width + height * height).toDouble();
  final inner = max(2.0, diagonal * innerFraction);
  final outer = max(inner + 2, diagonal * outerFraction);
  final step = max(1.0, diagonal * 0.003);

  var lumaSum = 0.0;
  var blueSum = 0.0;
  var redSum = 0.0;
  var samples = 0;

  final points = quad.points;
  for (var edge = 0; edge < 4; edge++) {
    final a = points[edge];
    final b = points[(edge + 1) % 4];
    final along = max(24, ((b.x - a.x).abs() + (b.y - a.y).abs()) ~/ 3);

    var nx = -(b.y - a.y);
    var ny = b.x - a.x;
    final normalLength = sqrt(nx * nx + ny * ny);
    if (normalLength == 0) continue;
    nx /= normalLength;
    ny /= normalLength;

    for (var i = 1; i < along; i++) {
      final t = i / along;
      final cx = a.x + (b.x - a.x) * t;
      final cy = a.y + (b.y - a.y) * t;

      var insideLuma = 0.0, insideBlue = 0.0, insideRed = 0.0;
      var outsideLuma = 0.0, outsideBlue = 0.0, outsideRed = 0.0;
      var insideCount = 0, outsideCount = 0;

      for (var d = inner; d <= outer; d += step) {
        for (final side in const [-1.0, 1.0]) {
          final x = (cx + nx * d * side).round();
          final y = (cy + ny * d * side).round();
          if (x < 0 || y < 0 || x >= width || y >= height) continue;
          final p = (y * width + x) * 4;
          final r = rgba[p], g = rgba[p + 1], bl = rgba[p + 2];
          final luma = 0.299 * r + 0.587 * g + 0.114 * bl;
          final cb = -0.168736 * r - 0.331264 * g + 0.5 * bl;
          final cr = 0.5 * r - 0.418688 * g - 0.081312 * bl;
          if (side < 0) {
            insideLuma += luma;
            insideBlue += cb;
            insideRed += cr;
            insideCount++;
          } else {
            outsideLuma += luma;
            outsideBlue += cb;
            outsideRed += cr;
            outsideCount++;
          }
        }
      }

      if (insideCount == 0 || outsideCount == 0) continue;

      final dLuma = insideLuma / insideCount - outsideLuma / outsideCount;
      final dBlue = insideBlue / insideCount - outsideBlue / outsideCount;
      final dRed = insideRed / insideCount - outsideRed / outsideCount;

      lumaSum += dLuma.abs();
      blueSum += dBlue.abs();
      redSum += dRed.abs();
      samples++;
    }
  }

  if (samples == 0) return 0;
  final meanLuma = lumaSum / samples;
  final meanBlue = blueSum / samples;
  final meanRed = redSum / samples;
  return sqrt(meanLuma * meanLuma + meanBlue * meanBlue + meanRed * meanRed);
}

/// [quad] 的两侧是不是两种不同的东西 —— 见 [boundaryColorStep]。
///
/// 判不过不是「检测失败」，而是「这个框不能用」：调用方应当退回不裁，而不是
/// 拿它去裁。
bool quadSeparatesRegions(
  Uint8List rgba,
  int width,
  int height,
  Quad quad, {
  double threshold = kMinBoundaryColorStep,
}) =>
    boundaryColorStep(rgba, width, height, quad) >= threshold;
