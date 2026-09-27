import 'dart:io';
import 'package:memos_flutter_app/application/attachments/queued_attachment_stager.dart';

Future<void> main() async {
  final sourceDir = await Directory.systemTemp.createTemp('codex_stage_src_');
  final supportDir = await Directory.systemTemp.createTemp('codex_stage_support_');
  try {
    final source = File('${sourceDir.path}${Platform.pathSeparator}gallery.png');
    await source.writeAsBytes(const [1, 2, 3, 4]);
    final stager = QueuedAttachmentStager(
      resolveSupportDirectory: () async => supportDir,
    );
    final sw = Stopwatch()..start();
    final staged = await stager.stageDraftAttachment(
      uid: 'u1',
      filePath: source.path,
      filename: 'gallery.png',
      mimeType: 'image/png',
      size: await source.length(),
      scopeKey: 'test-workspace',
    );
    sw.stop();
    print('OK ${sw.elapsedMilliseconds} ${staged.filePath} ${staged.size}');
  } finally {
    if (sourceDir.existsSync()) sourceDir.deleteSync(recursive: true);
    if (supportDir.existsSync()) supportDir.deleteSync(recursive: true);
  }
}
