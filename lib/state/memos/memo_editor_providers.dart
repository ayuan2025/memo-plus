import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'memo_editor_controller.dart' show MemoEditorPendingAttachment;
import 'memo_editor_controller.dart';

final memoEditorControllerProvider = Provider<MemoEditorController>((ref) {
  return MemoEditorController(ref);
});
