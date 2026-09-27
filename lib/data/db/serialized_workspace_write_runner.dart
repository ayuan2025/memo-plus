import 'dart:async';

class SerializedWorkspaceWriteRunner {
  final Map<String, Future<void>> _tails = <String, Future<void>>{};

  Future<T> run<T>(String key, Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _tails[key] ?? Future<void>.value();
    late final Future<void> current;
    current = previous
        .catchError((_) {})
        .then((_) async {
          final result = await action();
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        })
        .whenComplete(() {
          if (identical(_tails[key], current)) {
            _tails.remove(key);
          }
        });
    _tails[key] = current;
    return completer.future;
  }
}
