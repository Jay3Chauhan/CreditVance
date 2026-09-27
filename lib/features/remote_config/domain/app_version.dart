/// Semantic version from the installed build (`major.minor.patch`) plus the
/// store build number. Build numbers are compared separately from semver.
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final int build;

  const AppVersion({required this.major, required this.minor, required this.patch, this.build = 0});

  static final RegExp _semver = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  String get label => '$major.$minor.$patch';

  static AppVersion? tryParse(String raw) {
    final match = _semver.firstMatch(raw.trim());
    if (match == null) return null;
    return AppVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
    );
  }

  static AppVersion fromPackage({required String version, required String buildNumber}) {
    final parsed = tryParse(version) ?? const AppVersion(major: 1, minor: 0, patch: 0);
    return AppVersion(
      major: parsed.major,
      minor: parsed.minor,
      patch: parsed.patch,
      build: int.tryParse(buildNumber.trim()) ?? 0,
    );
  }

  @override
  int compareTo(AppVersion other) {
    final majorDiff = major.compareTo(other.major);
    if (majorDiff != 0) return majorDiff;
    final minorDiff = minor.compareTo(other.minor);
    if (minorDiff != 0) return minorDiff;
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion && major == other.major && minor == other.minor && patch == other.patch && build == other.build;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);
}
