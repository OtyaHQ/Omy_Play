import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Omy Play release files use the Omy Play product identity', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();
    final publisher = File('scripts/publish_r2.sh').readAsStringSync();
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final strings = File('android/app/src/main/res/values/strings.xml').readAsStringSync();
    final versionGenerator = File('scripts/generate_version_json.sh').readAsStringSync();

    expect(manifest, contains('android:label="Omy Play"'));
    expect(strings, contains('<string name="app_name">Omy Play</string>'));
    expect(workflow, contains('OmyPlay-arm64.apk'));
    expect(workflow, contains('OmyPlay-arm32.apk'));
    expect(workflow, contains('OmyPlay.aab'));
    expect(publisher, contains(r'releases/${RAW_TAG}/OmyPlay-arm64.apk'));
    expect(publisher, contains(r'releases/${RAW_TAG}/OmyPlay-arm32.apk'));
    expect(versionGenerator, contains('OmyPlay-arm64.apk'));
    expect(versionGenerator, contains('OmyPlay-arm32.apk'));

    expect(workflow, isNot(contains('OtyaPlayer')));
    expect(publisher, isNot(contains('OtyaPlayer')));
    expect(versionGenerator, isNot(contains('OtyaPlayer')));
  });
}
