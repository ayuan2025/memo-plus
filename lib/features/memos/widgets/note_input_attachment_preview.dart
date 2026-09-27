import 'package:flutter/material.dart';

import '../../../core/memoflow_palette.dart';
import '../../../state/memos/memo_composer_state.dart';
import 'attachment_processing_overlay.dart';

class NoteInputAttachmentPreviewStrip extends StatelessWidget {
  const NoteInputAttachmentPreviewStrip({
    super.key,
    required this.deferredTiles,
    required this.pendingTiles,
    this.tileSize = 62,
  });

  final List<Widget> deferredTiles;
  final List<Widget> pendingTiles;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    if (deferredTiles.isEmpty && pendingTiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: tileSize,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < deferredTiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                deferredTiles[i],
              ],
              for (var i = 0; i < pendingTiles.length; i++) ...[
                if (i > 0 || deferredTiles.isNotEmpty)
                  const SizedBox(width: 10),
                pendingTiles[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NoteInputDeferredVideoTile extends StatelessWidget {
  const NoteInputDeferredVideoTile({
    super.key,
    required this.isDark,
    required this.size,
    required this.thumbnailUrl,
    required this.headers,
    required this.progress,
    required this.busy,
    required this.isRemovable,
    required this.onOpen,
    required this.onRemove,
  });

  final bool isDark;
  final double size;
  final String thumbnailUrl;
  final Map<String, String> headers;
  final double progress;
  final bool busy;
  final bool isRemovable;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? MemoFlowPalette.borderDark
        : MemoFlowPalette.borderLight;
    final surfaceColor = isDark
        ? MemoFlowPalette.audioSurfaceDark
        : MemoFlowPalette.audioSurfaceLight;
    final removeBg = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.5);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.35 : 0.12);

    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                headers: headers,
                errorBuilder: (context, error, stackTrace) {
                  return NoteInputAttachmentFallback(
                    iconColor: Colors.white,
                    surfaceColor: surfaceColor,
                    isImage: false,
                    isVideo: true,
                  );
                },
              )
            else
              NoteInputAttachmentFallback(
                iconColor: Colors.white,
                surfaceColor: surfaceColor,
                isImage: false,
                isVideo: true,
              ),
            Container(color: Colors.black.withValues(alpha: 0.26)),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.2,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(onTap: onOpen, child: tile),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: (busy || !isRemovable) ? null : onRemove,
            child: _RemoveButton(backgroundColor: removeBg),
          ),
        ),
      ],
    );
  }
}

class NoteInputPendingAttachmentTile extends StatelessWidget {
  const NoteInputPendingAttachmentTile({
    super.key,
    required this.isImage,
    required this.isVideo,
    required this.hasFile,
    required this.skipCompression,
    required this.isReadyForSubmit,
    required this.processingStatus,
    required this.busy,
    required this.size,
    required this.surfaceColor,
    required this.tileBorderColor,
    required this.shadowColor,
    required this.removeBg,
    required this.content,
    required this.originalBadgeLabel,
    required this.onOpenImage,
    required this.onOpenVideo,
    required this.onRemove,
  });

  final bool isImage;
  final bool isVideo;
  final bool hasFile;
  final bool skipCompression;
  final bool isReadyForSubmit;
  final AttachmentProcessingStatus processingStatus;
  final bool busy;
  final double size;
  final Color surfaceColor;
  final Color tileBorderColor;
  final Color shadowColor;
  final Color removeBg;
  final Widget content;
  final String originalBadgeLabel;
  final VoidCallback onOpenImage;
  final VoidCallback onOpenVideo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tileRadius = BorderRadius.circular(14);
    final tile = isImage && hasFile
        ? SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: tileRadius,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: tileRadius,
                child: Stack(fit: StackFit.expand, children: [content]),
              ),
            ),
          )
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: tileRadius,
              border: Border.all(color: tileBorderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(borderRadius: tileRadius, child: content),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: (isImage && hasFile)
              ? onOpenImage
              : (isVideo && hasFile)
              ? onOpenVideo
              : null,
          child: tile,
        ),
        if (skipCompression && isImage)
          Positioned(
            left: 4,
            bottom: 4,
            child: IgnorePointer(
              child: NoteInputOriginalBadge(label: originalBadgeLabel),
            ),
          ),
        if (!isReadyForSubmit)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: tileRadius,
              child: AttachmentProcessingOverlay(status: processingStatus),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: busy ? null : onRemove,
            child: _RemoveButton(backgroundColor: removeBg),
          ),
        ),
      ],
    );
  }
}

class NoteInputAttachmentFallback extends StatelessWidget {
  const NoteInputAttachmentFallback({
    super.key,
    required this.iconColor,
    required this.surfaceColor,
    required this.isImage,
    this.isVideo = false,
  });

  final Color iconColor;
  final Color surfaceColor;
  final bool isImage;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor,
      alignment: Alignment.center,
      child: Icon(
        isImage
            ? Icons.image_outlined
            : (isVideo
                  ? Icons.videocam_outlined
                  : Icons.insert_drive_file_outlined),
        size: 22,
        color: iconColor,
      ),
    );
  }
}

class NoteInputOriginalBadge extends StatelessWidget {
  const NoteInputOriginalBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Icon(Icons.close, size: 12, color: Colors.white),
    );
  }
}
