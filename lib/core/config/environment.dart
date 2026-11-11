import 'dart:ffi';

/// Values that define the installed Otya application and must stay stable
/// across environments. These are safe to compile into the APK.
abstract final class AppContract {
  static const String appName = 'Otya Media';
  static const String appPackageId = 'com.otyaplayer.app';

  /// Otya's current authentication contract. The server is authoritative;
  /// keeping the client copy centralized prevents UI drift.
  static const int otpLength = 5;
  static const String otpExample = 'A1234';
  static final RegExp otpPattern = RegExp(r'^[A-Z][0-9]{4}$');

  /// Supported app UI locales. Language content belongs in ARB files, not here.
  static const String englishLocale = 'en';
  static const String lugandaLocale = 'lg';
}

/// Public, non-secret configuration that may change between releases or
/// environments. These values can be overridden with --dart-define.
///
/// IMPORTANT: --dart-define is configuration, not secret storage. Anything the
/// mobile app receives at runtime can ultimately be extracted from the APK or
/// process, so private credentials must remain on Cloudflare/server-side only.
abstract final class Environment {
  static const String workerUrl = String.fromEnvironment(
    'WORKER_URL',
    defaultValue: 'https://api.otya.site',
  );

  static const String publicSiteUrl = String.fromEnvironment(
    'PUBLIC_SITE_URL',
    defaultValue: 'https://otya.site',
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@otya.site',
  );

  // Compatibility aliases used throughout the current app.
  static const String appName = AppContract.appName;
  static const String appPackageId = AppContract.appPackageId;
  static const String websiteUrl = publicSiteUrl;

  // Canonical online API endpoints. Keep this list small: each online job has
  // one owner, while local playback/scanning continue without these services.
  static const String apiCrashUrl = '$workerUrl/api/crash-report';
  static const String checkUpdateUrl = '$workerUrl/check-update';
  static const String apiVersionUrl = '$workerUrl/api/version';
  static const String apiDeviceUrl = '$workerUrl/api/device';
  static const String apiFeedbackUrl = '$workerUrl/api/feedback';
  static const String latestUrl = '$workerUrl/latest';

  static const String arm64DownloadUrl = '$workerUrl/apk/arm64';
  static const String arm32DownloadUrl = '$workerUrl/apk/arm32';
  static const String downloadUrl = '$workerUrl/download/otya-player';
  static const String docsUrl = String.fromEnvironment(
    'DOCS_URL',
    defaultValue: 'https://docs.otya.site',
  );
  static const String spaceUrl = String.fromEnvironment(
    'SPACE_URL',
    defaultValue: 'https://space.otya.site',
  );
  static const String statusUrl = String.fromEnvironment(
    'STATUS_URL',
    defaultValue: 'https://status.otya.site',
  );

  // Compatibility endpoint aliases retained for existing feature modules.
  // All are derived from the configurable API/public origins above.
  static const String authUrl = '$workerUrl/auth';
  static const String appConfigUrl = '$workerUrl/api/app-config';
  static const String themesUrl = '$workerUrl/api/themes';
  static const String downloadPageUrl = '$publicSiteUrl/download/otya-player';

  static const String assetsUrl = String.fromEnvironment(
    'ASSETS_URL',
    defaultValue: 'https://assets.otya.site',
  );

  /// Additional, explicitly approved Otya HTTPS origins. This can include
  /// separately branded product domains without coupling them to the primary
  /// website's DNS suffix. Values are comma-separated at build time.
  static const String additionalTrustedOrigins = String.fromEnvironment(
    'OTYA_TRUSTED_ORIGINS',
    defaultValue: '',
  );

  static Iterable<String> _configuredHttpsHosts() sync* {
    final values = <String>[
      publicSiteUrl,
      workerUrl,
      docsUrl,
      spaceUrl,
      statusUrl,
      assetsUrl,
      ...additionalTrustedOrigins.split(',').map((value) => value.trim()),
    ];
    for (final value in values) {
      final uri = Uri.tryParse(value);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.userInfo.isEmpty &&
          uri.host.isNotEmpty) {
        yield uri.host.toLowerCase();
      }
    }
  }

  /// Exact hosts delivered to the native updater from the same Otya
  /// configuration. The Android bridge never maintains a separate domain list.
  static Set<String> get officialHosts => _configuredHttpsHosts().toSet();

  /// Otya WebView/update policy: trust configured HTTPS hosts exactly, plus
  /// subdomains of the configured primary host. Do not use substring matching.
  static bool isOfficialHost(String value) {
    final host = value.trim().toLowerCase();
    if (host.isEmpty) return false;

    final configuredHosts = officialHosts;
    final primary = Uri.tryParse(publicSiteUrl);
    final primaryHost = primary?.scheme == 'https'
        ? primary?.host.toLowerCase()
        : null;

    return configuredHosts.contains(host) ||
        (primaryHost != null &&
            (host == 'www.$primaryHost' || host.endsWith('.$primaryHost')));
  }

  /// Self-installing APK updates are opt-in. Keep disabled by default so a
  /// release cannot accidentally enable installer behavior.
  static const bool selfUpdateEnabled =
      bool.fromEnvironment('SELF_UPDATE', defaultValue: false);

  /// ABI used by update selection and backend device registration.
  ///
  /// A non-empty APP_ARCH remains an explicit build/test override. Normal
  /// production APKs detect the ABI they are actually running on because both
  /// split APKs otherwise share the same Dart compile-time default.
  static String get appArch {
    const override = String.fromEnvironment('APP_ARCH', defaultValue: '');
    if (override.isNotEmpty) return override;

    final abi = Abi.current();
    if (abi == Abi.androidArm) return 'arm32';
    if (abi == Abi.androidArm64) return 'arm64';

    // Keep emulator/development values truthful instead of silently claiming
    // arm64 on an unsupported architecture.
    return abi.toString();
  }
}
