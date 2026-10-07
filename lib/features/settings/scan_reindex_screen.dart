import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saf_stream/saf_stream.dart';

import '../../application/scan/scan_reindex_service.dart';
import '../../core/attachment_url.dart';
import '../../core/top_toast.dart';
import '../../data/models/attachment.dart';
import '../../data/models/local_memo.dart';
import '../../i18n/strings.g.dart';
import '../../state/memos/memo_mutation_service.dart';
import '../../state/scan/scan_metadata_provider.dart';
import '../../state/system/database_provider.dart';
import '../../state/system/session_provider.dart';
import 'settings_ui.dart';

/// Re-reads every page this app has already scanned.
///
/// Exists because an older build stored only a fragment of what it read, and
/// those pages stayed unsearchable for the words that were missing. Nothing
/// here can make a page worse: a re-read is only written back when it found
/// more than what was already stored, and the memo's update time is preserved
/// so a batch does not reshuffle the user's timeline.
class ScanReindexScreen extends ConsumerStatefulWidget {
  const ScanReindexScreen({super.key});

  @override
  ConsumerState<ScanReindexScreen> createState() => _ScanReindexScreenState();
}

class _ScanReindexScreenState extends ConsumerState<ScanReindexScreen> {
  bool _counting = true;
  bool _running = false;
  bool _stopRequested = false;
  int _found = 0;
  ScanReindexProgress? _progress;
  ScanReindexReport? _report;
  Dio? _dio;

  @override
  void initState() {
    super.initState();
    _countScans();
  }

  @override
  void dispose() {
    // Leaving mid-batch has to stop it, or the recogniser keeps running
    // against a screen that is no longer there.
    _stopRequested = true;
    super.dispose();
  }

  Future<List<LocalMemo>> _scanMemos() async {
    final db = ref.read(databaseProvider);
    final rows = await db.listMemosForExport(includeArchived: true);
    return rows
        .map(LocalMemo.fromDb)
        .where(ScanReindexService.isScanMemo)
        .toList(growable: false);
  }

  /// Refreshes the count, since the page may have sat open through another scan.
  Future<void> _countScans() async {
    final memos = await _scanMemos();
    if (!mounted) return;
    setState(() {
      _found = memos.length;
      _counting = false;
    });
  }

  Future<Uint8List?> _readBytes(Attachment attachment) async {
    final link = attachment.externalLink.trim();

    if (link.startsWith('file://')) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        final file = File(uri.toFilePath());
        if (file.existsSync()) return file.readAsBytes();
      }
      return null;
    }
    if (link.startsWith('content://')) {
      return SafStream().readFileBytes(link);
    }

    final account = ref.read(appSessionProvider).valueOrNull?.currentAccount;
    final url = resolveAttachmentRemoteUrl(account?.baseUrl, attachment);
    if (url == null || url.isEmpty) return null;

    final token = account?.personalAccessToken ?? '';
    final client = _dio ??= Dio();
    final response = await client.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
      ),
    );
    final data = response.data;
    return data == null ? null : Uint8List.fromList(data);
  }

  Future<void> _start() async {
    if (_running) return;
    final ocr = ref.read(localScanMetadataServiceProvider);
    if (!ocr.isSupported) {
      showTopToast(context, context.t.strings.legacy.msg_reindex_scans_unsupported);
      return;
    }

    setState(() {
      _running = true;
      _stopRequested = false;
      _report = null;
      _progress = null;
    });

    // Loading up front rather than reusing the count from initState: the user
    // may have scanned something while this screen sat open.
    final memos = await _scanMemos();
    if (!mounted) return;
    setState(() => _found = memos.length);

    final mutations = ref.read(memoMutationServiceProvider);
    final report = await ScanReindexService(
      ocr: ocr,
      readBytes: _readBytes,
    ).reindex(
      memos: memos,
      save: (memo, content) => mutations.updateMemoContent(
        memo,
        content,
        preserveUpdateTime: true,
      ),
      shouldStop: () => _stopRequested,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );

    if (!mounted) return;
    setState(() {
      _running = false;
      _report = report;
    });
  }

  void _stop() {
    if (!_running) return;
    setState(() => _stopRequested = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.strings.legacy;
    final theme = Theme.of(context);
    final progress = _progress;

    return SettingsPage(
      title: Text(t.msg_reindex_scans),
      onRefresh: _running ? null : _countScans,
      children: <Widget>[
        SettingsSection(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.msg_reindex_scans_intro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_counting)
                    const Center(child: CircularProgressIndicator())
                  else
                    Text(
                      _found == 0
                          ? t.msg_reindex_scans_none
                          : t.msg_reindex_scans_found
                              .replaceAll('{count}', '$_found'),
                      style: theme.textTheme.titleMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_running && progress != null) ...<Widget>[
          const SizedBox(height: 12),
          SettingsSection(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LinearProgressIndicator(
                      value: progress.total == 0
                          ? null
                          : progress.completed / progress.total,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${progress.completed} / ${progress.total}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (_report != null) ...<Widget>[
          const SizedBox(height: 12),
          SettingsSection(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_summary(), style: theme.textTheme.titleMedium),
                    if (_report!.failed > 0) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        t.msg_reindex_scans_failed
                            .replaceAll('{failed}', '${_report!.failed}'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        SettingsSection(
          children: <Widget>[
            SettingsNavigationRow(
              label: _running
                  ? t.msg_reindex_scans_stop
                  : t.msg_reindex_scans_start,
              leading: Icon(
                _running ? Icons.stop_outlined : Icons.auto_awesome_outlined,
                size: 20,
              ),
              trailingIcon: Icons.chevron_right,
              enabled: !_counting && (_running || _found > 0),
              onTap: _running ? _stop : _start,
            ),
          ],
        ),
      ],
    );
  }

  String _summary() {
    final t = context.t.strings.legacy;
    final report = _report!;
    if (report.cancelled) {
      return t.msg_reindex_scans_stopped
          .replaceAll('{done}', '${report.considered}');
    }
    return t.msg_reindex_scans_done
        .replaceAll('{improved}', '${report.improved}')
        .replaceAll('{unchanged}', '${report.unchanged}');
  }
}
