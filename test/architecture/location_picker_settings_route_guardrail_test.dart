import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('location picker delegates location settings navigation', () async {
    final source = await File(
      'lib/features/location_picker/show_location_picker.dart',
    ).readAsString();

    expect(source, isNot(contains('location_settings_screen.dart')));
    expect(source, isNot(contains('LocationSettingsScreen')));
    expect(source, isNot(contains('MaterialPageRoute')));
    expect(source, contains('LocationSettingsOpener'));
  });
}
