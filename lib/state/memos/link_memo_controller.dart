import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/memo.dart';
import 'memos_providers.dart';

class LinkMemoController {
  LinkMemoController(this._ref);

  final Ref _ref;

  Future<List<Memo>> loadMemos({required String query}) async {
    return _ref.read(memoSearchCoordinatorProvider).loadLinkMemos(query: query);
  }
}
