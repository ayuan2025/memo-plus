import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/scene_micro_guide_repository.dart';
import 'session_provider.dart';

class SceneMicroGuideState {
  const SceneMicroGuideState({required this.loaded, required this.seen});

  const SceneMicroGuideState.initial()
    : loaded = false,
      seen = const <SceneMicroGuideId>{};

  final bool loaded;
  final Set<SceneMicroGuideId> seen;

  bool isSeen(SceneMicroGuideId id) => seen.contains(id);

  SceneMicroGuideState copyWith({bool? loaded, Set<SceneMicroGuideId>? seen}) {
    return SceneMicroGuideState(
      loaded: loaded ?? this.loaded,
      seen: seen ?? this.seen,
    );
  }
}

final sceneMicroGuideRepositoryProvider = Provider<SceneMicroGuideRepository>((
  ref,
) {
  return SceneMicroGuideRepository(ref.watch(secureStorageProvider));
});

final sceneMicroGuideProvider =
    StateNotifierProvider<SceneMicroGuideController, SceneMicroGuideState>((
      ref,
    ) {
      return SceneMicroGuideController(
        ref.watch(sceneMicroGuideRepositoryProvider),
      );
    });

class SceneMicroGuideController extends StateNotifier<SceneMicroGuideState> {
  SceneMicroGuideController(this._repository)
    : super(const SceneMicroGuideState.initial()) {
    unawaited(load());
  }

  final SceneMicroGuideRepository _repository;

  Future<void> load() async {
    final seen = await _repository.read();
    if (!mounted) return;
    state = SceneMicroGuideState(loaded: true, seen: seen);
  }

  bool isSeen(SceneMicroGuideId id) => state.isSeen(id);

  Future<void> markSeen(SceneMicroGuideId id) async {
    final baseSeen = state.loaded ? state.seen : await _repository.read();
    final mergedSeen = {...baseSeen, ...state.seen};
    if (mergedSeen.contains(id)) {
      state = SceneMicroGuideState(loaded: true, seen: mergedSeen);
      return;
    }
    final next = {...mergedSeen, id};
    state = SceneMicroGuideState(loaded: true, seen: next);
    await _repository.write(next);
  }
}
