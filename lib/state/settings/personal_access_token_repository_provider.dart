import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/personal_access_token_repository.dart';
import '../system/session_provider.dart';

final personalAccessTokenRepositoryProvider = Provider<PersonalAccessTokenRepository>((ref) {
  return PersonalAccessTokenRepository(ref.watch(secureStorageProvider));
});

