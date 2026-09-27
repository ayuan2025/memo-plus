import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/repositories/ai_settings_repository.dart';

class AiProviderLogo extends StatelessWidget {
  const AiProviderLogo({
    super.key,
    required this.template,
    this.size = 40,
    this.iconSize = 22,
  });

  final AiProviderTemplate? template;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFFF4F4F5) : const Color(0xFFF8F8FA);
    final border = isDark
        ? Colors.black.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.08);
    final asset = template?.logoAsset?.trim();

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: border),
      ),
      child: asset == null || asset.isEmpty
          ? Icon(Icons.auto_awesome_rounded, size: iconSize, color: Colors.black87)
          : _AssetLogo(assetPath: asset),
    );
  }
}

class _AssetLogo extends StatelessWidget {
  const _AssetLogo({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const SizedBox.expand(
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.black87,
      ),
    );
  }
}
