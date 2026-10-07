import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/local_memo.dart';
import '../../../state/settings/note_display_theme_settings_provider.dart';
import 'memo_card_theme.dart';
import 'memo_share_card.dart';
import 'memo_theme_picker.dart';

/// 笔记分享卡片预览页：展示 [MemoShareCard]，支持「分享」与「保存到相册」。
///
/// 入口由笔记详情页的「分享为图片卡片」按钮打开（见 memo_detail_screen.dart）。
class MemoCardShareScreen extends ConsumerStatefulWidget {
  const MemoCardShareScreen({super.key, required this.memo});

  final LocalMemo memo;

  @override
  ConsumerState<MemoCardShareScreen> createState() =>
      _MemoCardShareScreenState();
}

class _MemoCardShareScreenState extends ConsumerState<MemoCardShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  /// 用户在本页临时改选的主题；为空时跟随设置里的全局笔记主题。
  MemoCardTheme? _themeOverride;
  bool _busy = false;

  Future<void> _export({required bool share}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final png = await captureWidgetPng(_cardKey, pixelRatio: 3);
      if (png == null) {
        _toast('导出失败：卡片未渲染');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/memo_card_${widget.memo.uid}.png');
      await file.writeAsBytes(png);
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(file.path)],
            text: 'memo+',
          ),
        );
      } else {
        final result = await ImageGallerySaver.saveImage(
          png,
          name: 'memo_card_${widget.memo.uid}',
        );
        final ok = result is Map && result['isSuccess'] == true;
        _toast(ok ? '已保存到相册' : '保存失败');
      }
    } catch (e) {
      _toast('导出失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalTheme = ref.watch(selectedMemoCardThemeProvider);
    final MemoCardTheme theme = _themeOverride ?? globalTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('分享卡片'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _busy ? null : () => _export(share: true),
            icon: const Icon(Icons.share),
            label: const Text('分享'),
          ),
          TextButton.icon(
            onPressed: _busy ? null : () => _export(share: false),
            icon: const Icon(Icons.download),
            label: const Text('保存'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: MemoShareCard(memo: widget.memo, theme: theme),
                ),
              ),
            ),
          ),
          _buildThemeSelector(),
        ],
      ),
    );
  }

  /// 底部横向主题选择条：点一颗 chip 即时切换预览里的纸面主题。
  Widget _buildThemeSelector() {
    final globalTheme = ref.watch(selectedMemoCardThemeProvider);
    final current = _themeOverride ?? globalTheme;
    return SafeArea(
      top: false,
      child: MemoThemePickerStrip(
        current: current,
        onSelected: (theme) => setState(() => _themeOverride = theme),
      ),
    );
  }
}
