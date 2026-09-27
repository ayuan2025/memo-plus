import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/app_channel.dart';

void main() {
  test('resolveAppChannel prefers Flutter flavor over dart define', () {
    expect(
      resolveAppChannel(flavor: 'full', appChannelDefine: 'play'),
      AppChannel.full,
    );
  });

  test('resolveAppChannel falls back to dart define when flavor missing', () {
    expect(
      resolveAppChannel(appChannelDefine: 'full'),
      AppChannel.full,
    );
  });

  test('resolveAppChannel defaults to play when unset', () {
    expect(resolveAppChannel(), AppChannel.play);
  });
}
