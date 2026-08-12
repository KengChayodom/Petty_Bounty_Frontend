import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import '../../data/profile_repository.dart';
import '../models/profile_models.dart';

/// Provider for ProfileRepository instance.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// AsyncNotifier provider for managing user profile state.
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, ProfileUserModel>(
        UserProfileNotifier.new);

class UserProfileNotifier extends AsyncNotifier<ProfileUserModel> {
  late final ProfileRepository _repository;

  @override
  Future<ProfileUserModel> build() async {
    _repository = ref.watch(profileRepositoryProvider);
    return await _repository.fetchProfile();
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await _repository.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return updated;
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchProfile());
  }
}

/// Provider for Hunter Stats (Earned points, Sighting count, Rescues count)
final hunterStatsProvider = FutureProvider<HunterStatsModel>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.fetchHunterStats();
});

/// Provider for Hunter Sighting Sent History list
final hunterHistoryProvider =
    FutureProvider<List<HunterSightingHistoryItem>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.fetchHunterHistory();
});

/// Provider for Pet Owner Posted Pets list
final ownerPostsProvider =
    FutureProvider<List<OwnerPostHistoryItem>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.fetchOwnerPosts();
});
