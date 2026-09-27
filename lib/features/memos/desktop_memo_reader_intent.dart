import 'package:flutter/foundation.dart';

import '../../data/models/local_memo.dart';

@immutable
class DesktopMemoReaderIntent {
  const DesktopMemoReaderIntent.open({required this.existing});

  final LocalMemo existing;
}
