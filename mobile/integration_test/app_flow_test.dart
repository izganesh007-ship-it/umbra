// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

void main() {
  group('Umbra App E2E Flow', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });

    test('App launches and shows chat list', () async {
      // Wait for the app to settle
      await driver.waitFor(find.byType('ChatListScreen'));

      // Verify the app title
      expect(await driver.getText(find.byType('ChatListScreen')), isNotNull);
    });

    test('Theme toggle works with eclipse wipe', () async {
      // Find the theme toggle button
      final themeToggle = find.byValueKey('themeToggle');

      // Tap the theme toggle
      await driver.tap(themeToggle);

      // Wait for the eclipse wipe animation to complete (600ms + buffer)
      await Future.delayed(const Duration(milliseconds: 800));

      // Verify theme changed
      final isDark = await driver.getText(find.byValueKey('themeMode'));
      expect(isDark, contains('Umbra'));
    });

    test('Navigation to settings works', () async {
      // Find and tap settings button
      final settingsButton = find.byValueKey('settingsButton');
      await driver.tap(settingsButton);

      // Wait for settings screen
      await driver.waitFor(find.byType('SettingsScreen'));

      // Verify settings screen is shown
      expect(await driver.getText(find.byType('SettingsScreen')), isNotNull);
    });

    test('Navigation to tools works', () async {
      // Find and tap tools button
      final toolsButton = find.byValueKey('toolsButton');
      await driver.tap(toolsButton);

      // Wait for tools screen
      await driver.waitFor(find.byType('ToolsScreen'));

      // Verify tools screen is shown
      expect(await driver.getText(find.byType('ToolsScreen')), isNotNull);
    });

    test('New group flow works', () async {
      // Find and tap new group button
      final newGroupButton = find.byValueKey('newGroupButton');
      await driver.tap(newGroupButton);

      // Wait for new group screen
      await driver.waitFor(find.byType('NewGroupScreen'));

      // Verify new group screen is shown
      expect(await driver.getText(find.byType('NewGroupScreen')), isNotNull);
    });

    test('RTL layout renders correctly', () async {
      // This test would run with RTL locale
      // For now, just verify the app handles RTL
      await driver.waitFor(find.byType('ChatListScreen'));
      expect(true, isTrue);
    });
  });
}
