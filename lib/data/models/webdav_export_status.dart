import 'webdav_export_signature.dart';

class WebDavExportStatus {
  const WebDavExportStatus({
    required this.webDavConfigured,
    required this.encSignature,
    required this.plainSignature,
    required this.plainDetected,
    required this.plainDeprecated,
    required this.plainDetectedAt,
    required this.plainRemindAfter,
    required this.lastExportSuccessAt,
    required this.lastUploadSuccessAt,
  });

  final bool webDavConfigured;
  final WebDavExportSignature? encSignature;
  final WebDavExportSignature? plainSignature;
  final bool plainDetected;
  final bool plainDeprecated;
  final String? plainDetectedAt;
  final String? plainRemindAfter;
  final String? lastExportSuccessAt;
  final String? lastUploadSuccessAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'webDavConfigured': webDavConfigured,
    'encSignature': encSignature?.toJson(),
    'plainSignature': plainSignature?.toJson(),
    'plainDetected': plainDetected,
    'plainDeprecated': plainDeprecated,
    'plainDetectedAt': plainDetectedAt,
    'plainRemindAfter': plainRemindAfter,
    'lastExportSuccessAt': lastExportSuccessAt,
    'lastUploadSuccessAt': lastUploadSuccessAt,
  };

  factory WebDavExportStatus.fromJson(Map<String, dynamic> json) {
    final rawEnc = json['encSignature'];
    final rawPlain = json['plainSignature'];
    return WebDavExportStatus(
      webDavConfigured: json['webDavConfigured'] == true,
      encSignature: rawEnc is Map
          ? WebDavExportSignature.fromJson(
              Map<Object?, Object?>.from(rawEnc).cast<String, dynamic>(),
            )
          : null,
      plainSignature: rawPlain is Map
          ? WebDavExportSignature.fromJson(
              Map<Object?, Object?>.from(rawPlain).cast<String, dynamic>(),
            )
          : null,
      plainDetected: json['plainDetected'] == true,
      plainDeprecated: json['plainDeprecated'] == true,
      plainDetectedAt: json['plainDetectedAt'] as String?,
      plainRemindAfter: json['plainRemindAfter'] as String?,
      lastExportSuccessAt: json['lastExportSuccessAt'] as String?,
      lastUploadSuccessAt: json['lastUploadSuccessAt'] as String?,
    );
  }
}
