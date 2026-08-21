import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leaderboard_repository.dart';
import '../data/models/rank_models.dart';

final leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((ref) => LeaderboardRepository());

const int _pageSize = 20;

// ---------------------------------------------------------------------------
// User (hunter) board
// ---------------------------------------------------------------------------

class UserRankState {
  final List<RankUser> entries;
  final RankUser? me;
  final bool initialLoading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;

  const UserRankState({
    this.entries = const [],
    this.me,
    this.initialLoading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  UserRankState copyWith({
    List<RankUser>? entries,
    RankUser? me,
    bool? initialLoading,
    bool? loadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return UserRankState(
      entries: entries ?? this.entries,
      me: me ?? this.me,
      initialLoading: initialLoading ?? this.initialLoading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class UserRankNotifier extends StateNotifier<UserRankState> {
  final LeaderboardRepository _repo;
  UserRankNotifier(this._repo) : super(const UserRankState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = const UserRankState(initialLoading: true);
    try {
      final page = await _repo.fetchUsers(limit: _pageSize, offset: 0);
      state = UserRankState(
        entries: page.entries,
        me: page.me,
        initialLoading: false,
        hasMore: page.entries.length == _pageSize,
      );
    } catch (e) {
      state = UserRankState(initialLoading: false, hasMore: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.initialLoading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page =
          await _repo.fetchUsers(limit: _pageSize, offset: state.entries.length);
      state = state.copyWith(
        entries: [...state.entries, ...page.entries],
        me: page.me ?? state.me,
        loadingMore: false,
        hasMore: page.entries.length == _pageSize,
      );
    } catch (_) {
      // Stop paginating on error; the rows already loaded stay usable.
      state = state.copyWith(loadingMore: false, hasMore: false);
    }
  }
}

final userRankProvider =
    StateNotifierProvider.autoDispose<UserRankNotifier, UserRankState>(
  (ref) => UserRankNotifier(ref.watch(leaderboardRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Bounty board (active missing pets by reward)
// ---------------------------------------------------------------------------

class BountyRankState {
  final List<RankBounty> entries;
  final bool initialLoading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;

  const BountyRankState({
    this.entries = const [],
    this.initialLoading = true,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  BountyRankState copyWith({
    List<RankBounty>? entries,
    bool? initialLoading,
    bool? loadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return BountyRankState(
      entries: entries ?? this.entries,
      initialLoading: initialLoading ?? this.initialLoading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class BountyRankNotifier extends StateNotifier<BountyRankState> {
  final LeaderboardRepository _repo;
  BountyRankNotifier(this._repo) : super(const BountyRankState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = const BountyRankState(initialLoading: true);
    try {
      final entries = await _repo.fetchBounties(limit: _pageSize, offset: 0);
      state = BountyRankState(
        entries: entries,
        initialLoading: false,
        hasMore: entries.length == _pageSize,
      );
    } catch (e) {
      state = BountyRankState(initialLoading: false, hasMore: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.initialLoading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final more = await _repo.fetchBounties(
          limit: _pageSize, offset: state.entries.length);
      state = state.copyWith(
        entries: [...state.entries, ...more],
        loadingMore: false,
        hasMore: more.length == _pageSize,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false, hasMore: false);
    }
  }
}

final bountyRankProvider =
    StateNotifierProvider.autoDispose<BountyRankNotifier, BountyRankState>(
  (ref) => BountyRankNotifier(ref.watch(leaderboardRepositoryProvider)),
);
