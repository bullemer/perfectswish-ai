/// App version information
/// This file is updated at build time to include version and build timestamp
class AppVersion {
  static const String version = '1.0.1';
  static const String buildDate = '2026-02-01';
  static const String buildTime = '11:48';
  
  static String get fullVersion => 'v$version ($buildDate $buildTime)';
}
