import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Omy Play release files use the product brand', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();
    final publisher = File('scripts/publish_r2.sh').readAsStringSync();
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android:label="Omy Play"'));
    expect(workflow, contains('OtyaPlayer-arm64.apk'));
    expect(workflow, contains('OtyaPlayer-arm32.apk'));
    expect(workflow, contains('OmyPlay.aab'));
    expect(publisher, contains('releases/\${RAW_TAG}/OtyaPlayer-arm64.apk'));
    expect(publisher, contains('releases/\${RAW_TAG}/OtyaPlayer-arm32.apk'));

    expect(workflow, isNot(contains('OTYA Player')));
    expect(publisher, isNot(contains('OTYA-Player-')));
    expect(publisher, isNot(contains('OtyaPlayer-arm64.apk')));
    expect(publisher, isNot(contains('OtyaPlayer-arm32.apk')));
  });
}
