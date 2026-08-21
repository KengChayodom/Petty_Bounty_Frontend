import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/rank_models.dart';
import '../domain/leaderboard_providers.dart';

const _blue = Color(0xFF3B5BFE);
const _gold = Color(0xFFF5C518);
const _silver = Color(0xFFC0CAD4);
const _bronze = Color(0xFFE3B98F);
const _scoreGreen = Color(0xFF10B981);
const _bountyOrange = Color(0xFFEE6D33);

/// "RANK LIST" — two boards: hunters by score, and active pets by bounty.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
          title: const Text(
            'RANK LIST',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: _blue,
            indicatorWeight: 3,
            labelColor: _blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.person)),
              Tab(icon: Icon(Icons.pets)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_UserBoard(), _BountyBoard()],
        ),
      ),
    );
  }
}

/// Rank pill: gold/silver/bronze for the podium, a light grey chip otherwise.
Widget _rankBadge(int rank) {
  final podium = rank <= 3;
  final color = switch (rank) {
    1 => _gold,
    2 => _silver,
    3 => _bronze,
    _ => const Color(0xFFF0F0F0),
  };
  return Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$rank',
      style: TextStyle(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w900,
        color: podium ? Colors.white : Colors.grey,
      ),
    ),
  );
}

Widget _avatar({String? url, required Widget fallback, double radius = 20}) {
  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFF0F0F0),
    backgroundImage: url != null ? CachedNetworkImageProvider(url) : null,
    child: url == null ? fallback : null,
  );
}

Widget _rankRow({
  required int rank,
  String? imageUrl,
  required Widget avatarFallback,
  required String title,
  required Widget trailing,
}) {
  return Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        _rankBadge(rank),
        const SizedBox(width: 12),
        _avatar(url: imageUrl, fallback: avatarFallback),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    ),
  );
}

Widget _errorRetry(Object err, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 32),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

/// Fires [onEnd] as the list nears its bottom, for infinite scroll.
bool _nearBottom(ScrollNotification n) =>
    n.metrics.pixels >= n.metrics.maxScrollExtent - 300;

// ---------------------------------------------------------------------------

class _UserBoard extends ConsumerStatefulWidget {
  const _UserBoard();
  @override
  ConsumerState<_UserBoard> createState() => _UserBoardState();
}

class _UserBoardState extends ConsumerState<_UserBoard> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userRankProvider);
    final notifier = ref.read(userRankProvider.notifier);

    if (state.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.entries.isEmpty) {
      return _errorRetry(state.error!, notifier.loadInitial);
    }

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (_nearBottom(n)) notifier.loadMore();
              return false;
            },
            child: ListView.builder(
              itemCount: state.entries.length + (state.loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= state.entries.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final u = state.entries[i];
                return _rankRow(
                  rank: u.rank,
                  imageUrl: u.profileImageUrl,
                  avatarFallback:
                      const Icon(Icons.person, size: 20, color: Colors.grey),
                  title: u.displayName,
                  trailing: Text(
                    '${u.totalScore}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (state.me != null) _YourStanding(me: state.me!),
      ],
    );
  }
}

class _YourStanding extends StatelessWidget {
  const _YourStanding({required this.me});
  final RankUser me;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1330),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _blue,
              child: Text(
                '${me.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR STANDING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    me.displayName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${me.totalScore}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _scoreGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BountyBoard extends ConsumerWidget {
  const _BountyBoard();

  static String _fmt(double amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      final s = k.truncateToDouble() == k ? k.toStringAsFixed(0)
          : k.toStringAsFixed(1);
      return '฿$s'
          'k';
    }
    return '฿${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bountyRankProvider);
    final notifier = ref.read(bountyRankProvider.notifier);

    if (state.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.entries.isEmpty) {
      return _errorRetry(state.error!, notifier.loadInitial);
    }
    if (state.entries.isEmpty) {
      return const Center(
        child: Text('No active bounties right now.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (_nearBottom(n)) notifier.loadMore();
        return false;
      },
      child: ListView.builder(
        itemCount: state.entries.length + (state.loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= state.entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final p = state.entries[i];
          return _rankRow(
            rank: p.rank,
            imageUrl: p.imageUrl,
            avatarFallback: const Icon(Icons.pets, size: 20, color: Colors.grey),
            title: p.petName,
            trailing: Text(
              _fmt(p.bountyAmount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _bountyOrange,
              ),
            ),
          );
        },
      ),
    );
  }
}
