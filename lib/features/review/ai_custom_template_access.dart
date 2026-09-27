import '../../data/ai/ai_settings_models.dart';

class AiCustomTemplateAccess {
  const AiCustomTemplateAccess({required this.canUseMultipleTemplates});

  static const int freeTemplateLimit = 1;

  final bool canUseMultipleTemplates;

  int get activeTemplateLimit => canUseMultipleTemplates
      ? AiSettings.maxCustomInsightTemplateCount
      : freeTemplateLimit;

  bool canCreateTemplate(int currentCount) {
    return currentCount < activeTemplateLimit &&
        currentCount < AiSettings.maxCustomInsightTemplateCount;
  }

  bool isTemplateLocked(
    List<AiCustomInsightTemplate> templates,
    String templateId,
  ) {
    if (canUseMultipleTemplates) return false;
    final normalized = templateId.trim();
    if (normalized.isEmpty) return false;
    final index = templates.indexWhere(
      (template) => template.templateId.trim() == normalized,
    );
    return index >= freeTemplateLimit;
  }
}
