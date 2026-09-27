import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/scan/document_scan_pipeline.dart';
import '../../core/app_localization.dart';
import '../../core/scan/document_scan.dart';
import '../../data/ai/ai_scan_metadata_service.dart';
import '../../state/scan/scan_metadata_provider.dart';
import '../../state/settings/ai_settings_provider.dart';

/// What the scan flow hands back to the composer.
class ScanReviewResult {
  const ScanReviewResult({
    required this.bytes,
    this.title = '',
    this.tags = const <String>[],
    this.body = '',
  });

  /// The finished page, encoded as JPEG.
  final Uint8List bytes;

  /// Empty unless the user asked for a reading and the model produced one.
  final String title;
  final List<String> tags;

  /// The full recognised text of the page when it was read on-device, or empty.
  ///
  /// Carried separately from [title] so a memo can show a short headline while
  /// still holding the entire OCR result — which is dropped into the note's
  /// (hidden) body rather than shown as the headline.
  final String body;

  bool get hasMetadata => title.isNotEmpty || tags.isNotEmpty;
}

/// Reviews one captured photo as a document page: shows the detected boundary,
/// lets the user pull the four corners onto the actual page edges, pick a
/// scanner colour mode, turn the page upright, and — if a model is configured —
/// ask it what the document is.
///
/// Pops with a [ScanReviewResult], or null when the user backs out. The caller
/// owns writing the page to a file — this screen never touches the filesystem,
/// so it stays usable from any entry point.
class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({
    super.key,
    required this.encoded,
    this.askForMetadata = true,
  });

  /// The untouched capture.
  final Uint8List encoded;

  /// Whether the "read this document" action should be offered at all.
  ///
  /// Callers that already know there is no model to ask can turn this off
  /// rather than making the screen re-derive it.
  final bool askForMetadata;

  /// Opens the review flow, returning the finished page or null.
  static Future<ScanReviewResult?> open(
    BuildContext context, {
    required Uint8List encoded,
    bool askForMetadata = true,
  }) {
    return Navigator.of(context).push<ScanReviewResult>(
      MaterialPageRoute<ScanReviewResult>(
        builder: (_) =>
            ScanReviewScreen(encoded: encoded, askForMetadata: askForMetadata),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

/// Radius, in logical pixels, within which a touch grabs a corner handle.
const double _kHandleGrabRadius = 44;

/// Radius the corner handles are drawn at.
const double _kHandleRadius = 12;

/// How long to wait after the boundary stops moving before re-rendering the
/// result thumbnail. Long enough that a drag does not queue a warp per frame,
/// short enough that the thumbnail feels like it is keeping up.
const Duration _kPreviewDebounce = Duration(milliseconds: 320);

/// How long to wait before re-rendering when the change came from a tap on the
/// colour strip rather than from dragging a corner: long enough to coalesce two
/// taps, short enough that the page appears to change on the tap itself.
const Duration _kPreviewRenderQuick = Duration(milliseconds: 60);

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  /// Corner order is the scanner pipeline's canonical one: top-left, top-right,
  /// bottom-right, bottom-left — in fractional [0,1] coordinates of the capture.
  List<Pt> _corners = const <Pt>[];

  int _imageWidth = 0;
  int _imageHeight = 0;

  bool _detecting = true;
  bool _autoDetected = false;
  bool _saving = false;
  int? _activeCorner;

  /// Whether the preview shows the raw capture with draggable corners rather
  /// than the finished page.
  ///
  /// The finished page is what the user came for, so that is what the screen
  /// opens on; the capture with its handles is a correction step, not the
  /// destination. It is also the only view in which a colour mode is visible at
  /// all — a filter changes the *page*, and the raw capture underneath is the
  /// same pixels whatever is picked.
  bool _adjustingEdges = false;

  String _filterName = defaultDocumentFilter.name;
  int _quarterTurns = 0;

  /// The rendered page: what the preview shows, and — so the work is not
  /// repeated — the payload that gets confirmed and that a model is asked to
  /// read.
  ///
  /// Deliberately *not* cleared whenever a setting changes. The last good page
  /// stays on screen while the next one is being made, so picking a colour mode
  /// swaps the preview rather than flashing a spinner.
  Uint8List? _pageBytes;

  /// True when [_pageBytes] no longer matches [_corners], [_filterName] or
  /// [_quarterTurns]. See [_pageBytes] for why the bytes stay put regardless.
  bool _pageStale = true;

  /// Numbers the renders so one that finishes late cannot overwrite a newer
  /// one that was requested after it.
  int _renderTicket = 0;

  Timer? _previewDebounce;

  bool _reading = false;
  String _title = '';
  List<String> _tags = const <String>[];
  String _body = '';

  /// Whether the automatic first reading has already been kicked off.
  ///
  /// The on-device reader runs once the finished page is up, so the title and
  /// tags are ready by the time the user confirms — but only once per screen,
  /// so later filter or rotation changes do not re-read the page.
  bool _autoReadTriggered = false;

  @override
  void initState() {
    super.initState();
    unawaited(_detectBoundary());
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }

  Future<void> _detectBoundary() async {
    setState(() {
      _detecting = true;
    });

    final detection = await detectScanBoundary(widget.encoded);
    if (!mounted) return;

    if (detection == null) {
      setState(() {
        _detecting = false;
        _corners = const <Pt>[];
        // No page to show and no boundary to place: staying on the finished-page
        // view would leave the screen spinning forever.
        _adjustingEdges = true;
      });
      _showMessage(
        context.tr(zh: '这张图片无法识别，无法扫描', en: 'This image could not be read'),
      );
      return;
    }

    _applyBoundary(
      detection.quad ??
          defaultScanBoundary(detection.imageWidth, detection.imageHeight),
      imageWidth: detection.imageWidth,
      imageHeight: detection.imageHeight,
      autoDetected: detection.found,
    );
  }

  void _applyBoundary(
    Quad quad, {
    required int imageWidth,
    required int imageHeight,
    required bool autoDetected,
  }) {
    final clamped = clampQuadToImage(quad, imageWidth, imageHeight);
    final normalized = normalizeQuad(clamped, imageWidth, imageHeight);
    setState(() {
      _detecting = false;
      _autoDetected = autoDetected;
      _imageWidth = imageWidth;
      _imageHeight = imageHeight;
      _corners = normalized.points;
      // Found on its own: the page goes up straight away, which is the whole
      // "photograph a document" gesture. Nothing found: the corners are only a
      // guess, so the handles come up for the user to place instead of showing
      // them a page cut to the wrong rectangle.
      _adjustingEdges = !autoDetected;
    });
    _schedulePreviewRender();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  Quad _normalizedQuad() => Quad(
    topLeft: _corners[0],
    topRight: _corners[1],
    bottomRight: _corners[2],
    bottomLeft: _corners[3],
  );

  /// The boundary to cut to, in the capture's own pixel coordinates.
  Quad? get _pixelQuad {
    if (_corners.length != 4 || _imageWidth <= 0 || _imageHeight <= 0) {
      return null;
    }
    return clampQuadToImage(
      scaleNormalizedQuad(_normalizedQuad(), _imageWidth, _imageHeight),
      _imageWidth,
      _imageHeight,
    );
  }

  bool get _hasUsableBoundary =>
      _pixelQuad != null && quadLongestEdge(_pixelQuad!) > 32;

  bool get _canConfirm => !_detecting && !_saving && _hasUsableBoundary;

  /// The settings that decide what the page looks like have changed, so the
  /// stored render no longer matches them.
  ///
  /// The existing render is deliberately left in place — only its freshness is
  /// marked down — so the preview keeps showing the last good page while the
  /// next one is being made.
  void _schedulePreviewRender({Duration delay = _kPreviewDebounce}) {
    _pageStale = true;
    _previewDebounce?.cancel();
    if (!_hasUsableBoundary) {
      // There is no page to show any more, so the old one has to go.
      if (_pageBytes != null) {
        setState(() => _pageBytes = null);
      }
      return;
    }
    _previewDebounce = Timer(delay, () {
      unawaited(_renderPage());
    });
  }

  /// Renders the page, or returns null when it could not be produced.
  Future<Uint8List?> _renderPage({bool immediate = false}) async {
    final quad = _pixelQuad;
    if (quad == null) return null;

    if (immediate) _previewDebounce?.cancel();

    final ticket = ++_renderTicket;
    final result = await renderScanPage(
      ScanPageRequest(
        encoded: widget.encoded,
        quad: quad,
        filterName: _filterName,
        quarterTurns: _quarterTurns,
      ),
    );
    if (!mounted) return null;
    if (!result.processed) return null;

    // A render that lands after a newer one was asked for is still the right
    // answer for whoever awaited it by name, but it must not take over the
    // preview from the newer one.
    if (ticket == _renderTicket) {
      setState(() {
        _pageBytes = result.bytes;
        _pageStale = false;
      });
      _maybeAutoRead();
    }
    return result.bytes;
  }

  /// The page to hand back: the cached render when it is current, otherwise a
  /// fresh one so the user is never handed a stale crop.
  Future<Uint8List?> _ensurePage() async {
    final cached = _pageBytes;
    if (cached != null && !_pageStale) return cached;
    return _renderPage(immediate: true);
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() {
      _saving = true;
    });

    final bytes = await _ensurePage();
    if (!mounted) return;

    if (bytes == null) {
      setState(() {
        _saving = false;
      });
      _showMessage(
        context.tr(zh: '处理失败，请重新拍摄', en: 'Could not process this capture'),
      );
      return;
    }

    Navigator.of(
      context,
    ).pop(ScanReviewResult(bytes: bytes, title: _title, tags: _tags, body: _body));
  }

  /// Kicks off the automatic first reading once the finished page is on screen.
  ///
  /// Called from the first successful page render. It reads only when the
  /// screen is offering a reading at all and the user is looking at the page
  /// rather than correcting its corners, so the recognition runs on the crop
  /// the user actually confirmed. The reading itself is silent — the title and
  /// tags showing up is the feedback.
  void _maybeAutoRead() {
    if (_autoReadTriggered || _adjustingEdges || !widget.askForMetadata) return;
    final localService = ref.read(localScanMetadataServiceProvider);
    final aiService = ref.read(aiScanMetadataServiceProvider);
    if (!localService.isSupported &&
        !aiService.isAvailable(ref.read(aiSettingsProvider))) {
      return;
    }
    _autoReadTriggered = true;
    unawaited(_readDocument(silent: true));
  }

  /// Reads the page and proposes a title and tags for it.
  ///
  /// [silent] skips the informational snackbars, which is what the automatic
  /// first read wants: it should just fill the title and tags without popping a
  /// banner on every scan. Hard failures (a page that could not be processed)
  /// are still reported.
  Future<void> _readDocument({bool silent = false}) async {
    if (_reading || _saving || _detecting) return;
    setState(() {
      _reading = true;
    });

    try {
      final bytes = await _ensurePage();
      if (!mounted) return;
      if (bytes == null) {
        _showMessage(
          context.tr(zh: '处理失败，请重新拍摄', en: 'Could not process this capture'),
        );
        return;
      }

      final local = await ref
          .read(localScanMetadataServiceProvider)
          .generate(
            imageBytes: bytes,
            scannedAt: DateTime.now(),
            fallbackPrefix: context.tr(zh: '扫描件', en: 'Scan'),
          );
      if (!mounted) return;
      if (local != null && !local.isEmpty) {
        setState(() {
          _title = local.title;
          _tags = local.tags;
          _body = local.text;
        });
        if (!silent) {
          _showMessage(
            context.tr(zh: '已生成，可在正文中修改', en: 'Suggested — edit it in the memo'),
          );
        }
        return;
      }

      final aiService = ref.read(aiScanMetadataServiceProvider);
      if (!aiService.isAvailable(ref.read(aiSettingsProvider))) {
        if (!silent) {
          _showMessage(
            context.tr(
              zh: '没能从这一页读出文字',
              en: 'No text could be read from this page',
            ),
          );
        }
        return;
      }

      final outcome = await aiService.generate(
        settings: ref.read(aiSettingsProvider),
        imageBytes: bytes,
        language: context.appLanguage,
      );
      if (!mounted) return;

      final draft = outcome.draft;
      if (draft == null) {
        _showMessage(_failureMessage(outcome.failure));
        return;
      }

      setState(() {
        _title = draft.title;
        _tags = draft.tags;
      });
      _showMessage(
        context.tr(zh: '已生成，可在正文中修改', en: 'Suggested — edit it in the memo'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reading = false;
        });
      }
    }
  }

  String _failureMessage(AiScanMetadataFailure failure) {
    return switch (failure) {
      AiScanMetadataFailure.requestFailed => context.tr(
        zh: '生成失败，请检查 AI 设置或网络',
        en: 'Could not reach the model — check AI settings or your network',
      ),
      AiScanMetadataFailure.noRoute => context.tr(
        zh: '还没有可用的 AI 模型',
        en: 'No AI model configured',
      ),
      _ => context.tr(zh: '未能识别出标题与标签', en: 'Nothing readable was returned'),
    };
  }

  void _dragCorner(int index, Offset localPosition, Rect imageRect) {
    if (_corners.length != 4 || imageRect.isEmpty) return;
    final normalizedX = ((localPosition.dx - imageRect.left) / imageRect.width)
        .clamp(0.0, 1.0);
    final normalizedY = ((localPosition.dy - imageRect.top) / imageRect.height)
        .clamp(0.0, 1.0);
    setState(() {
      final next = List<Pt>.from(_corners);
      next[index] = Pt(normalizedX, normalizedY);
      _corners = next;
      _autoDetected = false;
    });
  }

  void _endDrag() {
    _activeCorner = null;
    _schedulePreviewRender();
  }

  int? _cornerAt(Offset localPosition, Rect imageRect) {
    if (_corners.length != 4 || imageRect.isEmpty) return null;
    int? nearest;
    double nearestDistance = double.infinity;
    for (int i = 0; i < _corners.length; i++) {
      final point = _toLocal(_corners[i], imageRect);
      final distance = (point - localPosition).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = i;
      }
    }
    return nearestDistance <= _kHandleGrabRadius ? nearest : null;
  }

  Offset _toLocal(Pt normalized, Rect imageRect) => Offset(
    imageRect.left + normalized.x * imageRect.width,
    imageRect.top + normalized.y * imageRect.height,
  );

  @override
  Widget build(BuildContext context) {
    final aiSettings = ref.watch(aiSettingsProvider);
    // The on-device reader needs no setup of any kind, so the action is offered
    // whenever it can run at all. A configured model is only a fallback for
    // pages the rules cannot make sense of, never a precondition.
    final canAsk =
        widget.askForMetadata &&
        (ref.read(localScanMetadataServiceProvider).isSupported ||
            ref.read(aiScanMetadataServiceProvider).isAvailable(aiSettings));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.tr(zh: '扫描文档', en: 'Scan document')),
        actions: [
          IconButton(
            tooltip: context.tr(zh: '旋转', en: 'Rotate'),
            onPressed: _detecting
                ? null
                : () {
                    setState(() {
                      _quarterTurns = (_quarterTurns + 1) % 4;
                    });
                    _schedulePreviewRender(delay: _kPreviewRenderQuick);
                  },
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
          ),
          if (_adjustingEdges)
            IconButton(
              tooltip: context.tr(zh: '重新检测边缘', en: 'Detect edges again'),
              onPressed: _detecting ? null : () => unawaited(_detectBoundary()),
              icon: const Icon(Icons.auto_fix_high_outlined),
            ),
          IconButton(
            tooltip: _adjustingEdges
                ? context.tr(zh: '完成', en: 'Done')
                : context.tr(zh: '调整边缘', en: 'Adjust edges'),
            onPressed: _detecting
                ? null
                : () {
                    // Leaving the handles is only ever "show me the page again",
                    // so the preview has to catch up with whatever was dragged.
                    final wasAdjusting = _adjustingEdges;
                    setState(() => _adjustingEdges = !_adjustingEdges);
                    if (wasAdjusting) {
                      _schedulePreviewRender(delay: _kPreviewRenderQuick);
                    }
                  },
            icon: Icon(_adjustingEdges ? Icons.check : Icons.crop_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildPreview(context)),
            if (_detecting)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr(zh: '正在查找纸张边缘…', en: 'Finding page edges…'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            else ...[
              if (!_autoDetected)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    context.tr(
                      zh: '未自动识别到边缘，请拖动四角对准纸张',
                      en: 'No edges detected — drag the corners onto the page',
                    ),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              _buildResultStrip(context, canAsk: canAsk),
              if (_title.isNotEmpty || _tags.isNotEmpty)
                _buildMetadataSummary(context),
              _buildFilterStrip(context),
              _buildBottomBar(context),
            ],
          ],
        ),
      ),
    );
  }

  /// The preview: the finished page by default, or the raw capture with corner
  /// handles while the boundary is being corrected.
  ///
  /// The page comes first because it is what the scan is *for*, and because a
  /// colour mode is only visible on it — the capture underneath is the same
  /// pixels whatever filter is picked.
  Widget _buildPreview(BuildContext context) {
    final pageBytes = _pageBytes;
    // No page, and none on the way either — a boundary too small to cut, say —
    // so the corner handles are the only useful thing left to put up.
    if (_adjustingEdges || (pageBytes == null && !_detecting)) {
      return _buildEdgeEditor(context);
    }
    if (pageBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Zoomable: the reason to show the page rather than the capture is being
    // able to check that the text came out legible.
    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.memory(
          pageBytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  /// The raw capture with draggable corner handles, used to correct where the
  /// page's edges actually are.
  Widget _buildEdgeEditor(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(_imageWidth.toDouble(), _imageHeight.toDouble());
        final fitted = (_imageWidth > 0 && _imageHeight > 0)
            ? applyBoxFit(BoxFit.contain, size, constraints.biggest)
            : null;
        final imageRect = fitted == null
            ? Rect.zero
            : Alignment.center.inscribe(
                fitted.destination,
                Offset.zero & constraints.biggest,
              );

        return Stack(
          fit: StackFit.expand,
          children: [
            if (imageRect.isEmpty)
              Center(
                child: _detecting
                    ? const CircularProgressIndicator()
                    : Text(
                        context.tr(
                          zh: '无法读取这张图片',
                          en: 'This image could not be read',
                        ),
                        style: const TextStyle(color: Colors.white54),
                      ),
              )
            else ...[
              Positioned.fromRect(
                rect: imageRect,
                child: Image.memory(
                  widget.encoded,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    _activeCorner = _cornerAt(details.localPosition, imageRect);
                  },
                  onPanUpdate: (details) {
                    final corner = _activeCorner;
                    if (corner == null) return;
                    _dragCorner(corner, details.localPosition, imageRect);
                  },
                  onPanEnd: (_) => _endDrag(),
                  child: CustomPaint(
                    painter: _ScanQuadPainter(
                      imageRect: imageRect,
                      corners: _corners
                          .map((p) => _toLocal(p, imageRect))
                          .toList(),
                      activeCorner: _activeCorner,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// The "read this document" action plus a thumbnail of the finished page, so
  /// the crop, rotation and filter can be judged without leaving the screen.
  Widget _buildResultStrip(BuildContext context, {required bool canAsk}) {
    final pageBytes = _pageBytes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          // Only worth showing while the preview is the raw capture: once the
          // page itself is on screen, this is just a smaller copy of it.
          if (_adjustingEdges) ...[
            Container(
              width: 52,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              clipBehavior: Clip.antiAlias,
              child: pageBytes == null
                  ? Center(
                      child: _hasUsableBoundary
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              context.tr(zh: '无效', en: 'n/a'),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                    )
                  : Image.memory(pageBytes, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: canAsk
                ? OutlinedButton.icon(
                    onPressed: (_reading || _saving || _detecting)
                        ? null
                        : () => unawaited(_readDocument()),
                    icon: _reading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(
                      _title.isNotEmpty || _tags.isNotEmpty
                          ? context.tr(zh: '重新生成标题/标签', en: 'Suggest again')
                          : context.tr(
                              zh: '生成标题/标签',
                              en: 'Suggest title & tags',
                            ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  )
                : Text(
                    context.tr(
                      zh: '当前平台无法离线识别文字，可在设置中配置 AI 模型',
                      en: 'Text recognition is unavailable on this platform — configure an AI model instead',
                    ),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_title.isNotEmpty)
              Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            for (final tag in _tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterStrip(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: documentFiltersList.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = documentFiltersList[index];
          return Center(
            child: ChoiceChip(
              label: Text(_filterLabel(context, filter.name)),
              selected: _filterName == filter.name,
              onSelected: (_) {
                if (_filterName == filter.name) return;
                setState(() {
                  _filterName = filter.name;
                });
                // The preview *is* the page here, so a colour mode has to land
                // on the tap: sitting out the drag debounce reads as "nothing
                // happened".
                _schedulePreviewRender(delay: _kPreviewRenderQuick);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(
              context.tr(zh: '取消', en: 'Cancel'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _canConfirm ? () => unawaited(_confirm()) : null,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(context.tr(zh: '使用该扫描件', en: 'Use this page')),
          ),
        ],
      ),
    );
  }
}

String _filterLabel(BuildContext context, String name) {
  return switch (name) {
    'Original' => context.tr(zh: '原图', en: 'Original'),
    'Auto' => context.tr(zh: '自动', en: 'Auto'),
    'Lighten' => context.tr(zh: '增亮', en: 'Lighten'),
    'Grayscale' => context.tr(zh: '灰度', en: 'Grayscale'),
    'B&W' => context.tr(zh: '黑白', en: 'B&W'),
    'Whiteboard' => context.tr(zh: '白板', en: 'Whiteboard'),
    _ => name,
  };
}

/// Draws the crop boundary over the preview: everything outside the quad is
/// dimmed, the four edges are stroked, and each corner gets a grab handle.
class _ScanQuadPainter extends CustomPainter {
  const _ScanQuadPainter({
    required this.imageRect,
    required this.corners,
    required this.activeCorner,
  });

  final Rect imageRect;
  final List<Offset> corners;
  final int? activeCorner;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4 || imageRect.isEmpty) return;

    final polygon = Path()..addPolygon(corners, true);

    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      polygon,
    );
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.45));

    canvas.drawPath(
      polygon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );

    for (int i = 0; i < corners.length; i++) {
      final isActive = i == activeCorner;
      canvas.drawCircle(
        corners[i],
        isActive ? _kHandleRadius + 3 : _kHandleRadius,
        Paint()..color = isActive ? Colors.white : Colors.white70,
      );
      canvas.drawCircle(
        corners[i],
        isActive ? _kHandleRadius + 3 : _kHandleRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black54,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanQuadPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.activeCorner != activeCorner ||
        !listEquals(oldDelegate.corners, corners);
  }
}
