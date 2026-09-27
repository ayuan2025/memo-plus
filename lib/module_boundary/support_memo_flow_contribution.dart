import 'package:flutter/widgets.dart';

class SupportMemoFlowContribution {
  const SupportMemoFlowContribution({
    required this.id,
    required this.order,
    required this.builder,
  });

  final String id;
  final int order;
  final WidgetBuilder builder;
}
