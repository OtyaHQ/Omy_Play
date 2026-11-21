import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omy_play/core/config/environment.dart';

void main() {
  test('Android notification surfaces use the canonical Otya brand', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final channels = File(
      'lib/core/services/shared_notification_plugin.dart',
    ).readAsStringSync();
    final push = File(
      'lib/core/services/push_notification_service.dart',
    ).readAsStringSync();

    expect(
      mainSource,
      contains("androidNotificationChannelName: 'Otya — Now Playing'"),
    );
    expect(mainSource, contains('notificationColor: AppColors.brandBlue'));
    expect(channels, contains("'Otya — Updates'"));
    expect(channels, contains("'Otya — Announcements'"));
    expect(channels, contains("'Otya Tools — Progress'"));
    expect(channels, contains("'Otya Tools — Complete'"));
    expect(channels, contains("'Otya Tools — Errors'"));
    expect(push, contains("'Otya — Updates'"));
    expect(push, contains("final title = 'Otya \$version is ready'"));
    expect(push, contains("summaryText: 'Official Otya update'"));
    expect(push, isNot(contains("contentTitle: 'Otya \$version is available'")));
    expect(push, contains("'Otya — Announcements'"));
    expect(push, contains("uri.scheme != 'https'"));
    expect(push, contains('Environment.isOfficialHost(uri.host)'));
    expect(mainSource, isNot(contains("androidNotificationChannelName: 'OTYA")));
  });

  test('Otya uses the approved artwork and exact brand palette', () {
    final colors = File('lib/app/theme/app_colors.dart').readAsStringSync();
    final logo = File('lib/shared/widgets/otya_logo_v2.dart').readAsStringSync();
    final brandNote = File(
      'assets/branding/README-current-mark.md',
    ).readAsStringSync();

    expect(colors, contains('Color(0xFF1677FF)'));
    expect(colors, contains('Color(0xFF08265C)'));
    expect(colors, contains('Color(0xFF050812)'));
    expect(logo, contains('assets/branding/otya_master_lockup.webp'));
    expect(logo, contains('assets/branding/otya_orbital_mark.webp'));
    expect(logo, isNot(contains('assets/branding/otya_mark_current.png')));
    expect(logo, contains('One ecosystem. Endless possibilities.'));
    expect(brandNote, contains('Omy Play'))
    expect(brandNote, contains('Do not redraw the orbital symbol or wordmark'));
  });

  test('official network hosts use the exact shared Otya allow-list', () {
    expect(Environment.isOfficialHost('otya.site'), isTrue);
    expect(Environment.isOfficialHost('api.otya.site'), isTrue);
    expect(Environment.isOfficialHost('space.otya.site'), isTrue);
    expect(Environment.isOfficialHost('OTYA.SITE'), isTrue);
    for (final host in [
      'petersmartlink.com',
      'evil.otya.site',
      'otya.site.evil.example',
      'evilotya.site',
      'example.com',
    ]) {
      expect(Environment.isOfficialHost(host), isFalse, reason: host);
    }
  });

  test('Together join keeps network details behind user-facing language', () {
    final source = File(
      'lib/features/together/presentation/nearby_together_join_sheet.dart',
    ).readAsStringSync();

    expect(source, contains("hintText: 'Paste the invite here'"));
    expect(source, contains('Otya reuses what you already watched'));
    expect(source, contains('The video stays between your phones.'));
    expect(source, isNot(contains("hintText: 'ws://")));
    expect(source, isNot(contains('Reuse watched bytes')));
    expect(source, isNot(contains('OTYA reuses what you already watched')));
  });
}
