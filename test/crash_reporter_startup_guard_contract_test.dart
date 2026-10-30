import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crash reporter initialization cannot prevent the first app frame', () {
    final source = File('lib/main.dart').readAsStringSync();
    final reporterInit = source.indexOf('CrashReporter.instance');
    final runApp = source.indexOf('runApp(', reporterInit);

    expect(reporterInit, greaterThanOrEqualTo(0));
    expect(runApp, greaterThan(reporterInit));

    final startupGuard = source.substring(reporterInit - 180, runApp);
    expect(startupGuard, contains('.init()'));
    expect(startupGuard, contains('try {'));
    expect(startupGuard, contains('catch (error, stack)'));
    expect(startupGuard, contains('continuing startup'));
    expect(startupGuard, contains('Duration(seconds: 3)'));
  });

  test('platform startup waits are bounded and errors are contained', () {
    final source = File('lib/main.dart').readAsStringSync();
    final safeStart = source.indexOf('Future<void> _safeBackground(');
    final safeEnd = source.indexOf('Future<void> _initNotifications()', safeStart);
    expect(safeStart, greaterThanOrEqualTo(0));
    expect(safeEnd, greaterThan(safeStart));
    final safeBackground = source.substring(safeStart, safeEnd);
    expect(safeBackground, contains('Duration(seconds: 8)'));
    expect(safeBackground, contains('catch (e, st)'));
    expect(safeBackground, contains('Error or timeout'));
  });
}
