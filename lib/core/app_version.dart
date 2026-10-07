/// Version comparison for update checks.
///
/// One implementation on purpose: an update that the startup banner offers and
/// the settings page calls "already up to date" is a support ticket nobody can
/// reproduce, so every place that answers "is the remote version newer?" reads
/// the same numbers out of the same string.
library;

/// The first three numeric segments of [version], zero-filled.
///
/// Only the numbers matter and only the first three: `1.0.59-pro`, `1.0.59+60`
/// and `1.0.59` are the same release, and a segment that is not a bare number
/// (`v2`, `2rc1`) still contributes the digits it contains rather than silently
/// becoming zero. A `+build` or `-suffix` is dropped whole.
List<int> parseVersionTriplet(String version) {
  if (version.trim().isEmpty) return const [0, 0, 0];
  final trimmed = version.split(RegExp(r'[-+]')).first;
  final parts = trimmed.split('.');
  final values = <int>[0, 0, 0];
  for (var i = 0; i < 3; i++) {
    if (i >= parts.length) break;
    final match = RegExp(r'\d+').firstMatch(parts[i]);
    if (match == null) continue;
    values[i] = int.tryParse(match.group(0) ?? '') ?? 0;
  }
  return values;
}

/// Negative when [left] is older than [right], zero when they are the same
/// release, positive when [left] is newer.
int compareVersionTriplets(String left, String right) {
  final leftParts = parseVersionTriplet(left);
  final rightParts = parseVersionTriplet(right);
  for (var i = 0; i < 3; i++) {
    final diff = leftParts[i].compareTo(rightParts[i]);
    if (diff != 0) return diff;
  }
  return 0;
}

/// Whether [remote] is a newer release than [local].
bool isNewerVersion(String remote, String local) =>
    compareVersionTriplets(remote, local) > 0;
