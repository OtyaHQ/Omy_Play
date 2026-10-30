import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crash reporter initialization cannot prevent the first app frame', () {
    final source = File('lib/main.dart').readAsStringSync();
    final reporterInit = source.indexOf('await CrashReporter.instance.init()');
    final runApp = source.indexOf('runApp(', reporterInit);

    expect(reporterInit, greaterThanOrEqualTo(0));
    expect(runApp, greaterThan(reporterInit));

    final startupGuard = source.substring(reporterInit - 180, runApp);
    expect(startupGuard, contains('try {'));
    expect(startupGuard, contains('catch (error, stack)'));
    expect(startupGuard, contains('continuing startup'));
  });
}
