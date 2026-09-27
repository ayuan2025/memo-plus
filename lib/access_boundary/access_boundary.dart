import 'access_decision.dart';
import 'app_capability.dart';

abstract interface class AccessBoundary {
  AccessDecision decisionFor(AppCapability capability);
}
