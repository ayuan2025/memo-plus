import 'package:flutter/material.dart';

import '../../../data/models/local_memo.dart';
import '../memo_card_action.dart';
import 'memo_card_action_menu.dart';

List<MemoCardActionDescriptor> buildMemoDetailActionDescriptors({
  required BuildContext context,
  required LocalMemo memo,
  required bool readOnly,
  bool includeCopy = true,
}) {
  if (readOnly) return const <MemoCardActionDescriptor>[];
  return buildMemoCardActionDescriptors(
    context: context,
    memo: memo,
    includeCopy: includeCopy,
  );
}

Future<MemoCardAction?> showMemoDetailActionPopover({
  required BuildContext context,
  required LocalMemo memo,
  required bool readOnly,
  BuildContext? anchorContext,
  Offset? globalPosition,
  bool includeCopy = true,
}) {
  return showMemoActionPopover(
    context: context,
    actions: buildMemoDetailActionDescriptors(
      context: context,
      memo: memo,
      readOnly: readOnly,
      includeCopy: includeCopy,
    ),
    anchorContext: anchorContext,
    globalPosition: globalPosition,
  );
}
