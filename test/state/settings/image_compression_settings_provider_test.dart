import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/image_compression_settings.dart';
import 'package:memos_flutter_app/state/settings/image_compression_settings_provider.dart';

void main() {
  test('play Android uses system photo picker with global original prompt', () {
    final policy = resolveImageCompressionUiPolicy(
      settings: ImageCompressionSettings.defaults,
      isAndroidPlatform: true,
      isPlayChannel: true,
    );

    expect(policy.enabled, isTrue);
    expect(policy.useSystemPhotoPicker, isTrue);
    expect(
      policy.originalSelectionMode,
      ImageOriginalSelectionMode.globalBeforePick,
    );
    expect(policy.shouldPromptOriginalBeforePick, isTrue);
    expect(policy.showOriginalToggle, isFalse);
  });

  test('full Android keeps inline original toggle', () {
    final policy = resolveImageCompressionUiPolicy(
      settings: ImageCompressionSettings.defaults,
      isAndroidPlatform: true,
      isPlayChannel: false,
    );

    expect(policy.useSystemPhotoPicker, isFalse);
    expect(
      policy.originalSelectionMode,
      ImageOriginalSelectionMode.inlinePerAsset,
    );
    expect(policy.showOriginalToggle, isTrue);
    expect(policy.shouldPromptOriginalBeforePick, isFalse);
  });

  test('disabled compression hides original controls on all channels', () {
    final disabledSettings = ImageCompressionSettings.defaults.copyWith(
      enabled: false,
    );

    final playPolicy = resolveImageCompressionUiPolicy(
      settings: disabledSettings,
      isAndroidPlatform: true,
      isPlayChannel: true,
    );
    final fullPolicy = resolveImageCompressionUiPolicy(
      settings: disabledSettings,
      isAndroidPlatform: true,
      isPlayChannel: false,
    );

    expect(
      playPolicy.originalSelectionMode,
      ImageOriginalSelectionMode.hidden,
    );
    expect(
      fullPolicy.originalSelectionMode,
      ImageOriginalSelectionMode.hidden,
    );
    expect(playPolicy.useSystemPhotoPicker, isTrue);
    expect(fullPolicy.useSystemPhotoPicker, isFalse);
  });
}
