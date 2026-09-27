class DesktopWorkspaceSnapshot {
  const DesktopWorkspaceSnapshot({
    required this.currentKey,
    required this.hasCurrentAccount,
    required this.hasLocalLibrary,
  });

  final String? currentKey;
  final bool hasCurrentAccount;
  final bool hasLocalLibrary;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'currentKey': currentKey,
      'hasCurrentAccount': hasCurrentAccount,
      'hasLocalLibrary': hasLocalLibrary,
    };
  }

  static DesktopWorkspaceSnapshot fromJson(Map<Object?, Object?> json) {
    final rawKey = json['currentKey'];
    return DesktopWorkspaceSnapshot(
      currentKey: rawKey is String && rawKey.trim().isNotEmpty ? rawKey : null,
      hasCurrentAccount: json['hasCurrentAccount'] == true,
      hasLocalLibrary: json['hasLocalLibrary'] == true,
    );
  }
}
