import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/scan/live_scan_detector.dart';
import '../../core/app_localization.dart';
import '../../core/scan/document_scan.dart';
import '../../core/scan/src/models/quad.dart';
import '../../core/scan/src/quad_smoothing.dart';

/// Photographs a document with the page's edges outlined while the user aims.
///
/// This is the scanner's own camera rather than the system camera app: the
/// whole point of the screen is the outline that tracks the paper, and that is
/// only possible while the frames belong to us. [capture] returns the still's
/// path, or null when the user backed out.
///
/// The outline is a *preview*, never the crop. Once the still is in hand the
/// page is found again at full resolution by the review screen, so nothing here
/// — the sensor's quarter turn, the preview's aspect, the frame's downscale —
/// can decide what actually gets cut. If every one of those assumptions were
/// wrong, the worst that happens is a misplaced outline; the page still comes
/// out right.
class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  /// Whether this platform can outline the page during aiming.
  ///
  /// Needs a camera that streams frames. `camera_windows` does not, which is
  /// why the desktop keeps the plain capture screen and finds the page after
  /// the shutter instead of before it.
  static bool get canTrackLivePage =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<String?> capture(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ScanCameraScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

/// Raised when the device reports no cameras at all.
///
/// A `CameraException` would be the natural carrier, but building one is not
/// something the plugin's contract invites callers to do — this one is ours.
class _NoCameraAvailableException implements Exception {
  const _NoCameraAvailableException();

  @override
  String toString() => '_NoCameraAvailableException';
}

/// Smallest gap between two searches of the viewfinder.
const Duration _kMinSearchInterval = Duration(milliseconds: 90);

/// How thick the outline is drawn, in logical pixels.
const double _kOutlineStroke = 3;

/// Radius of the corner dots on the outline.
const double _kOutlineCornerRadius = 7;

/// How many searches in a row may come back empty before the outline is
/// dropped instead of being held over from the last frame.
///
/// Three is a compromise: a reflection or a blink lasts a frame or two, while a
/// page genuinely leaving the frame shows no sign of coming back.
const int _kMaxMissedFrames = 3;

/// How long the ring showing where focus was re-aimed stays on screen.
const Duration _kFocusRingDuration = Duration(milliseconds: 900);

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  CameraController? _controller;
  bool _initializing = true;
  String? _errorMessage;

  /// The page found in the most recent frame, in normalized *preview*
  /// coordinates — upright, which is the space the overlay paints in.
  Quad? _pageOutline;

  /// The same boundary in the frame's own pixel coordinates, handed back to the
  /// detector as "where the outline already is". Kept in frame space because
  /// that is the space the detector works in.
  Quad? _pageInFrame;

  /// True while a frame is being searched. Frames arriving meanwhile are
  /// dropped rather than queued, so a slow device degrades to fewer detections
  /// per second instead of an ever-growing backlog.
  bool _searching = false;

  /// How many searches in a row have come back empty. Used to tell a momentary
  /// flicker — a reflection, a blink, the detector latching onto the desk for
  /// one frame — from the page having genuinely left the frame.
  int _missedFrames = 0;

  bool _capturing = false;

  /// Clockwise turn the sensor's output needs in order to look upright.
  int _sensorOrientation = 0;

  /// Set when the platform refuses to stream frames. The screen still takes a
  /// photo; the page is just found after the shutter rather than during aiming.
  bool _outlineUnavailable = false;

  /// Time since the last frame was handed to the detector, used to space
  /// searches out rather than run one on every frame.
  final Stopwatch _sinceLastSearch = Stopwatch()..start();

  /// Where the operator last asked the camera to focus, in normalized preview
  /// coordinates, or null while the automatic centre lock is in effect.
  Offset? _focusPoint;

  /// Timer that fades the focus ring out again.
  Timer? _focusRingTimer;

  @override
  void initState() {
    super.initState();
    // The outline is placed by assuming an upright preview, and a phone held
    // sideways would invalidate the sensor turn the overlay is built on. A
    // document scan is an upright gesture anyway.
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]),
    );
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    _focusRingTimer?.cancel();
    _focusRingTimer = null;
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(_releaseCamera(controller));
    }
    super.dispose();
  }

  Future<void> _releaseCamera(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // Already torn down by the platform; disposing below is what matters.
    }
    await controller.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _failCamera(const _NoCameraAvailableException());
        return;
      }

      // The back camera is the one pointed at paper, but a device with only a
      // front camera should still scan rather than refuse.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        // YUV on Android means the first plane already *is* luminance, which
        // is the entire grey image the edge pipeline wants. iOS has no such
        // plane and hands over BGRA instead.
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _sensorOrientation = camera.sensorOrientation;
        _initializing = false;
      });
      await _lockExposureAndFocus(controller);
      await _startOutlineTracking(controller);
    } catch (error) {
      _failCamera(error);
    }
  }

  /// Reports that the camera could not be started at all.
  ///
  /// Takes the error rather than a ready-made message so the localized string
  /// is only built once [mounted] is known: the failure surfaces after an
  /// await, and reading `context` there without that check is exactly what
  /// `use_build_context_synchronously` guards against.
  void _failCamera(Object error) {
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _errorMessage = _friendlyCameraError(error);
    });
  }

  /// Pins auto-focus and auto-exposure to the middle of the frame and locks
  /// them there.
  ///
  /// A photographed page is flat, and the thing that has to stay sharp is its
  /// text — which is small. The sensor's own AF/AE re-evaluates continuously,
  /// and every re-evaluation can rack focus by a pixel or two or shift exposure
  /// for a frame; that is precisely while the recogniser is expected to be
  /// reading the strokes. Pointing both controls at the centre — where the page
  /// usually is — and locking them makes the framing steady and the characters
  /// consistent from frame to frame.
  ///
  /// Point locking is not available on every device, and every failure here is
  /// cosmetic: without it the scan still works, it just focuses on whatever the
  /// sensor decides on its own. So no step is allowed to fail the camera.
  Future<void> _lockExposureAndFocus(CameraController controller) async {
    await _quietly(() => controller.setFocusPoint(const Offset(0.5, 0.5)));
    await _quietly(() => controller.setExposurePoint(const Offset(0.5, 0.5)));
    await _quietly(() => controller.setFocusMode(FocusMode.locked));
    await _quietly(() => controller.setExposureMode(ExposureMode.locked));
  }

  /// Re-aims focus and exposure at the tapped spot and re-locks them.
  ///
  /// The centre lock is right most of the time, but a corner of a receipt, a
  /// line of numbers low on the page, or a crease across the sheet is not the
  /// centre — and text that the sensor focused on the middle of the paper will
  /// read as blurry wherever it actually sits.
  Future<void> _focusAt(Offset point) async {
    final controller = _controller;
    if (controller == null) return;

    final clamped = Offset(
      point.dx.clamp(0.0, 1.0),
      point.dy.clamp(0.0, 1.0),
    );

    // Unlocking first is what makes the re-aim take effect on the platforms
    // that refuse to move an AF point while the mode is `locked`.
    await _quietly(() => controller.setFocusMode(FocusMode.auto));
    await _quietly(() => controller.setExposureMode(ExposureMode.auto));
    await _quietly(() => controller.setFocusPoint(clamped));
    await _quietly(() => controller.setExposurePoint(clamped));
    await _quietly(() => controller.setFocusMode(FocusMode.locked));
    await _quietly(() => controller.setExposureMode(ExposureMode.locked));

    if (!mounted) return;
    setState(() => _focusPoint = clamped);
    _focusRingTimer?.cancel();
    _focusRingTimer = Timer(_kFocusRingDuration, () {
      if (!mounted) return;
      setState(() => _focusPoint = null);
    });
  }

  /// Runs [action], swallowing whatever it throws.
  ///
  /// Every camera control here is optional on a given device; a screen that
  /// refuses to open because `setFocusPoint` is unsupported would be a much
  /// worse outcome than a slightly softer scan.
  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Deliberately ignored — see the call site.
    }
  }

  Future<void> _startOutlineTracking(CameraController controller) async {
    try {
      await controller.startImageStream(_onFrame);
    } catch (_) {
      // Some devices will not stream and capture at once, or refuse the stream
      // outright. Losing the outline costs a nicety, not the feature, so the
      // screen carries on and says so.
      if (!mounted) return;
      setState(() => _outlineUnavailable = true);
    }
  }

  void _onFrame(CameraImage image) {
    if (_searching || _capturing) return;
    // The pipeline is quick enough to run on nearly every frame, which would
    // keep the CPU — and the battery — busy for no visible gain. The outline
    // only has to keep up with a hand, not with the sensor.
    if (_sinceLastSearch.elapsed < _kMinSearchInterval) return;

    final luminance = _luminanceOf(image);
    if (luminance == null) return;

    _sinceLastSearch
      ..reset()
      ..start();
    _searching = true;
    unawaited(_search(luminance));
  }

  Future<void> _search(
    ({Uint8List gray, int width, int height}) luminance,
  ) async {
    try {
      final found = await findPageInLiveFrame(
        LiveScanFrame(
          gray: luminance.gray,
          width: luminance.width,
          height: luminance.height,
          previousQuad: _pageInFrame,
        ),
      );
      if (!mounted) return;

      Quad? outline;
      if (found != null) {
        // Smoothing happens in frame space, where the detector and the previous
        // quad share a coordinate system; the painted outline is derived from
        // the smoothed result so what is drawn is what the next frame builds on.
        final previous = _pageInFrame;
        outline = previous == null ? found : smoothQuad(previous, found);
        _missedFrames = 0;
      } else {
        // A frame in which no page at all was found is more often a blink, a
        // reflection sweeping across the lens, or the detector latching onto
        // the desk for one frame, than the page having left the frame. Erasing
        // the outline on those would make it strobe.
        _missedFrames++;
        if (_missedFrames < _kMaxMissedFrames) outline = _pageInFrame;
      }

      _pageInFrame = outline;
      setState(() {
        _pageOutline = outline == null
            ? null
            : frameQuadToPreview(
                normalizedFrameQuad(
                  outline,
                  luminance.width,
                  luminance.height,
                ),
                _sensorOrientation,
              );
      });
    } finally {
      _searching = false;
    }
  }

  /// The grey image inside one camera frame, or null when the frame's format is
  /// one this build does not know how to read.
  ({Uint8List gray, int width, int height})? _luminanceOf(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    if (image.format.group == ImageFormatGroup.bgra8888) {
      return grayFromBgraPlane(
        plane.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
      );
    }

    // Android builds disagree about what to call YUV_420_888 — some report it
    // as `unknown` rather than `yuv420`. Its first plane is the luminance plane
    // either way, so a frame with a full set of planes is read as one rather
    // than dropped: treating it correctly costs nothing, and refusing would
    // cost the outline on exactly the devices this feature is for.
    if (image.format.group == ImageFormatGroup.yuv420 ||
        image.planes.length >= 3) {
      return grayFromLumaPlane(
        plane.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
      );
    }
    return null;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);

    try {
      // Frames and a still compete for the same pipeline: on Android the
      // capture fails outright while frames are still being delivered.
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (error) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyCameraError(error))));
      // The shutter has to keep working, so aiming resumes where it left off.
      await _startOutlineTracking(controller);
    }
  }

  String _friendlyCameraError(Object error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
        case 'CameraAccessDeniedWithoutPrompt':
        case 'CameraAccessRestricted':
          return context.tr(
            zh: '没有相机权限，请在系统设置中允许本应用使用相机',
            en: 'Camera access is denied — allow it for this app in system settings',
          );
      }
    }
    if (error is _NoCameraAvailableException) {
      return context.tr(zh: '没有找到可用的相机', en: 'No camera was found');
    }
    return context.tr(zh: '相机启动失败', en: 'The camera could not be started');
  }

  String? get _hint {
    if (_outlineUnavailable) {
      return context.tr(
        zh: '此设备不支持取景预览，拍照后会自动识别纸张边缘',
        en: 'Live outlining is unavailable here — edges are found after the shot',
      );
    }
    if (_pageOutline != null) {
      return context.tr(zh: '已找到纸张边缘', en: 'Page edges found');
    }
    return context.tr(zh: '将纸张放入画面', en: 'Point at the page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(context),
          if (_controller != null && _errorMessage == null) ...[
            _buildCloseButton(context),
            _buildShutter(context),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _controller;
    if (controller == null || _errorMessage != null) {
      return _buildCameraError(context);
    }
    return _buildViewfinder(controller);
  }

  Widget _buildCameraError(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 42,
                color: Colors.white54,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ??
                    context.tr(zh: '相机不可用', en: 'The camera is unavailable'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr(zh: '返回', en: 'Back')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null ||
        previewSize.width <= 0 ||
        previewSize.height <= 0) {
      return const Center(child: CircularProgressIndicator());
    }

    // previewSize is reported in sensor orientation, which is landscape on a
    // phone held upright: the rectangle the user actually sees is it transposed.
    final source = Size(previewSize.height, previewSize.width);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        final rect = Alignment.center.inscribe(
          applyBoxFit(BoxFit.contain, source, available).destination,
          Offset.zero & available,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(rect: rect, child: CameraPreview(controller)),
            Positioned.fromRect(
              rect: rect,
              child: GestureDetector(
                // A tap here is the shutter; focusing has to be a different
                // gesture or there would be no way to re-aim without
                // photographing the spot first.
                onLongPressStart: _capturing
                    ? null
                    : (details) => unawaited(
                        _focusAt(
                          Offset(
                            details.localPosition.dx / available.width,
                            details.localPosition.dy / available.height,
                          ),
                        ),
                      ),
                child: CustomPaint(
                  painter: _PageOutlinePainter(quad: _pageOutline),
                ),
              ),
            ),
            if (_focusPoint != null)
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FocusRingPainter(point: _focusPoint!),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _capturing ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ),
      ),
    );
  }

  Widget _buildShutter(BuildContext context) {
    final hint = _hint;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            _buildShutterButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShutterButton(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(zh: '拍照', en: 'Take photo'),
      child: GestureDetector(
        onTap: _capturing ? null : () => unawaited(_capture()),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: _capturing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Marks the spot focus and exposure were last aimed at, so a long press
/// gives visible feedback — the camera's own focus box is usually hidden and
/// refocusing a flat page changes nothing the eye can see.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({required this.point});

  /// Tap position as a 0-1 fraction of the preview box.
  final Offset point;

  static const Color _kColor = Color(0xFFFFC947);
  static const double _kRadius = 26;
  static const double _kArm = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(point.dx * size.width, point.dy * size.height);
    final box = Rect.fromCenter(
      center: center,
      width: _kRadius * 2,
      height: _kRadius * 2,
    );

    // Four corner brackets: the conventional camera reticle, and it stays
    // readable over a page full of text where a filled circle would not.
    final arms = <Rect>[
      Rect.fromLTRB(box.left, box.top, box.left + _kArm, box.top + 3),
      Rect.fromLTRB(box.left, box.top, box.left + 3, box.top + _kArm),
      Rect.fromLTRB(box.right - _kArm, box.top, box.right, box.top + 3),
      Rect.fromLTRB(box.right - 3, box.top, box.right, box.top + _kArm),
      Rect.fromLTRB(box.left, box.bottom - 3, box.left + _kArm, box.bottom),
      Rect.fromLTRB(box.left, box.bottom - _kArm, box.left + 3, box.bottom),
      Rect.fromLTRB(
        box.right - _kArm,
        box.bottom - 3,
        box.right,
        box.bottom,
      ),
      Rect.fromLTRB(box.right - 3, box.bottom - _kArm, box.right, box.bottom),
    ];

    final paint = Paint()..color = _kColor;
    for (final arm in arms) {
      canvas.drawRect(arm, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) =>
      oldDelegate.point != point;
}

/// Draws the tracked page: the paper stays lit, everything around it dims, and
/// the four corners are marked so the user can tell the outline is on the sheet
/// rather than on the desk behind it.
class _PageOutlinePainter extends CustomPainter {
  const _PageOutlinePainter({required this.quad});

  /// The boundary in normalized preview coordinates, or null while no page has
  /// been found yet.
  final Quad? quad;

  /// The colour the outline is drawn in. Deliberately not a Material accent:
  /// the thing it sits on is a camera feed, not a themed surface.
  static const Color _kOutlineColor = Color(0xFF4ADE80);

  @override
  void paint(Canvas canvas, Size size) {
    final boundary = quad;
    if (boundary == null) return;

    final corners = boundary.points
        .map((p) => Offset(p.x * size.width, p.y * size.height))
        .toList();
    final polygon = Path()..addPolygon(corners, true);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        polygon,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    canvas.drawPath(
      polygon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kOutlineStroke
        ..color = _kOutlineColor,
    );

    for (final corner in corners) {
      canvas.drawCircle(
        corner,
        _kOutlineCornerRadius,
        Paint()..color = _kOutlineColor,
      );
      canvas.drawCircle(
        corner,
        _kOutlineCornerRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PageOutlinePainter oldDelegate) =>
      !identical(oldDelegate.quad, quad);
}
