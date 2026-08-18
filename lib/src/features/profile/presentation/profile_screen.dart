import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../routing/app_router.dart';
import '../../home_map/data/location_publisher.dart';
import '../domain/models/profile_models.dart';
import '../domain/providers/profile_providers.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/hunter_tab_content.dart';
import 'widgets/owner_tab_content.dart';
import 'widgets/profile_header_widget.dart';
import 'widgets/role_tab_toggle_widget.dart';

/// Full Dual-Mode Profile Screen connected to real Backend APIs & Riverpod state.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTab = 0; // 0 = Hunter, 1 = Pet Owner

  Future<void> _logout() async {
    await FcmService.instance.unregisterForCurrentUser();
    LocationPublisher.instance.stop();
    await ref.read(authServiceProvider).signOut();
    // Deliberately NO ref.invalidate here. Invalidating after signOut made the
    // providers refetch immediately in a signed-out state (no access token ->
    // backend 401), and because they were cached at root scope those errors
    // were still there when the next account opened this screen. The providers
    // are autoDispose instead: the router redirects to /login, this screen
    // unmounts, and the cache is dropped for free.
  }

  void _openEditProfileDialog(String currentName, String? currentPhoto) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return EditProfileDialog(
          currentDisplayName: currentName,
          currentPhotoUrl: currentPhoto,
          // Returns whether the save succeeded, so the dialog knows whether
          // it's safe to close (on failure it stays open so the user's
          // typed changes aren't lost and they can just retry).
          onSave: (newName, newPhoto) async {
            try {
              await ref.read(userProfileProvider.notifier).updateProfile(
                    displayName: newName,
                    photoUrl: newPhoto,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              return true;
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update profile: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return false;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final hunterStatsAsync = ref.watch(hunterStatsProvider);
    final hunterHistoryAsync = ref.watch(hunterHistoryProvider);
    final ownerPostsAsync = ref.watch(ownerPostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(hunterStatsProvider);
          ref.invalidate(hunterHistoryProvider);
          ref.invalidate(ownerPostsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // USER INFO HEADER WIDGET WITH REAL DATA
              profileAsync.when(
                data: (profile) => ProfileHeaderWidget(
                  displayName: profile.displayName,
                  phone: profile.phone ?? '',
                  email: profile.email ?? '',
                  photoUrl: profile.profileImageUrl,
                  onEditPressed: () => _openEditProfileDialog(
                    profile.displayName,
                    profile.profileImageUrl,
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Could not load your profile: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(userProfileProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

              // ROLE TAB TOGGLE WIDGET (HUNTER vs PET OWNER)
              RoleTabToggleWidget(
                selectedTab: _selectedTab,
                onTabSelected: (index) => setState(() => _selectedTab = index),
              ),

              const SizedBox(height: 16),

              // TAB BODY CONTENT WITH REAL PROVIDERS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _selectedTab == 0
                    ? _buildTabBody(
                        loading: hunterStatsAsync.isLoading ||
                            hunterHistoryAsync.isLoading,
                        error: hunterStatsAsync.error ?? hunterHistoryAsync.error,
                        onRetry: () {
                          ref.invalidate(hunterStatsProvider);
                          ref.invalidate(hunterHistoryProvider);
                        },
                        content: () =>
                            _buildHunterTab(hunterStatsAsync, hunterHistoryAsync),
                      )
                    : _buildTabBody(
                        loading: ownerPostsAsync.isLoading,
                        error: ownerPostsAsync.error,
                        onRetry: () => ref.invalidate(ownerPostsProvider),
                        content: () => _buildOwnerTab(ownerPostsAsync),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Loading/error are indistinguishable from a genuine "no activity yet"
  /// zero if left to `.value` alone — this makes a real backend failure
  /// visible (with a retry) instead of silently looking like an empty tab.
  Widget _buildTabBody({
    required bool loading,
    required Object? error,
    required VoidCallback onRetry,
    required Widget Function() content,
  }) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Could not load this tab: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    return content();
  }

  Widget _buildHunterTab(
    AsyncValue hunterStatsAsync,
    AsyncValue hunterHistoryAsync,
  ) {
    // .value is null both while loading and on error — 0 is the honest
    // placeholder either way, never a made-up positive number.
    final stats = hunterStatsAsync.value;
    final List<HunterSightingHistoryItem> historyItems =
        hunterHistoryAsync.value ?? const <HunterSightingHistoryItem>[];

    return HunterTabContent(
      earnedPoints: stats?.totalScore ?? 0,
      sightingCount: stats?.sightingsSubmitted ?? 0,
      rescuesCount: stats?.sightingsVerified ?? 0,
      historyItems: historyItems,
    );
  }

  Widget _buildOwnerTab(AsyncValue ownerPostsAsync) {
    final List<OwnerPostHistoryItem> postItems =
        ownerPostsAsync.value ?? const <OwnerPostHistoryItem>[];
    final recoversCount = postItems
        .where((p) => p.status == PostStatus.rescued)
        .length;

    return OwnerTabContent(
      postsCount: postItems.length,
      recoversCount: recoversCount,
      postItems: postItems,
      onViewSightingsPressed: (item) {
        context.push(
          '${AppRoutes.statusTracker}/${item.id}',
          extra: {
            'petName': item.petName,
            'petImageUrl': item.petImageUrl,
            'isResolved': item.status == PostStatus.rescued,
          },
        );
      },
    );
  }
}
