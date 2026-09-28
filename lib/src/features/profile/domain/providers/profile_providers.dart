import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_models.dart';
import '../../data/profile_repository.dart';
import '../models/profile_models.dart';

/// Provider for ProfileRepository instance.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// AsyncNotifier provider for managing user profile state.
///
/// autoDispose: leaving the Profile screen drops the cache, so a different
/// account signing in during the same app session can never be served the
/// previous user's profile — nor a stale error cached at the moment of logout.
final userProfileProvider =
    AsyncNotifierProvider.autoDispose<UserProfileNotifier, ProfileUserModel>(
        UserProfileNotifier.new);

class UserProfileNotifier extends AutoDisposeAsyncNotifier<ProfileUserModel> {
  // Deliberately a getter, NOT a `late final` field assigned inside build():
  // Riverpod reuses the same notifier instance across rebuilds (invalidate,
  // pull-to-refresh), so a second build() would re-assign the field and throw
  // `LateInitializationError: Field '_repository' has already been initialized`.
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<ProfileUserModel> build() async {
    return await ref.watch(profileRepositoryProvider).fetchProfile();
  }

  Future<void> updateProfile({
    String? username,
    String? phone,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await _repository.updateProfile(
        username: username,
        phone: phone,
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
final hunterStatsProvider =
    FutureProvider.autoDispose<HunterStatsModel>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.fetchHunterStats();
});

/// Provider for Hunter Sighting Sent History list
final hunterHistoryProvider =
    FutureProvider.autoDispose<List<HunterSightingHistoryItem>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.fetchHunterHistory();
});

/// Provider for Pet Owner Posted Pets list
final ownerPostsProvider =
    FutureProvider.autoDispose<List<OwnerPostHistoryItem>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.fetchOwnerPosts();
});
