import 'package:flutter/foundation.dart';

import '../../data/models/compose_draft.dart';
import '../../data/models/local_memo.dart';

enum DesktopMemoEditorIntentKind { create, edit }

@immutable
class DesktopMemoEditorIntent {
  const DesktopMemoEditorIntent._({
    required this.kind,
    this.existing,
    this.initialText,
    this.initialAttachmentPaths = const <String>[],
    this.ignoreDraft = false,
    this.initialCreateDraft,
    this.initialEditDraft,
  });

  const DesktopMemoEditorIntent.create({
    String? initialText,
    List<String> initialAttachmentPaths = const <String>[],
    bool ignoreDraft = false,
    ComposeDraftRecord? initialCreateDraft,
  }) : this._(
         kind: DesktopMemoEditorIntentKind.create,
         initialText: initialText,
         initialAttachmentPaths: initialAttachmentPaths,
         ignoreDraft: ignoreDraft,
         initialCreateDraft: initialCreateDraft,
       );

  const DesktopMemoEditorIntent.edit({
    required LocalMemo existing,
    ComposeDraftRecord? initialEditDraft,
  }) : this._(
         kind: DesktopMemoEditorIntentKind.edit,
         existing: existing,
         initialEditDraft: initialEditDraft,
       );

  final DesktopMemoEditorIntentKind kind;
  final LocalMemo? existing;
  final String? initialText;
  final List<String> initialAttachmentPaths;
  final bool ignoreDraft;
  final ComposeDraftRecord? initialCreateDraft;
  final ComposeDraftRecord? initialEditDraft;

  bool get isCreate => kind == DesktopMemoEditorIntentKind.create;
  bool get isEdit => kind == DesktopMemoEditorIntentKind.edit;
}
