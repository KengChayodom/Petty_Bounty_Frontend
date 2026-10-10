import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_service.dart';
import '../../data/lost_pet_post_repository.dart';

final lostPetPostRepositoryProvider = Provider<LostPetPostRepository>((ref) {
  final authService = ref.read(authServiceProvider);
  return LostPetPostRepository(authService);
});
