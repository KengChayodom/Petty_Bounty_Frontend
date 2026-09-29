import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_glass.dart';
import '../../../core/ui/adaptive/breakpoints.dart';
import '../../../core/ui/skeleton/skeleton.dart';
import '../data/models/rank_models.dart';
import '../domain/leaderboard_providers.dart';

// Medal colours stay: they mean first, second and third, not "brand".
const _gold = Color(0xFFF5C518);
const _silver = Color(0xFFC0CAD4);
const _bronze = Color(0xFFE3B98F);

/// Score, kept deliberately apart from [kBrand]. Bounty is money and reads
/// orange everywhere in the app; score is points and would be conflated with it
/// if the two shared a colour. Deep enough to clear AA on white.
const _scoreGreen = Color(0xFF047857);

/// A surface set just into the page — rank chips, avatars, the standing card.
const _lifted = Color(0x0F120A04);
const _hairline = Color(0x14120A04);

/// "RANK LIST" — two boards: hunters by score, and active pets by bounty.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kDaylight,
        appBar: AppBar(
          backgroundColor: kDaylight,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kInk),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
          title: const Text(
            'RANK LIST',
            style: TextStyle(
              color: kInk,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: kBrandDeep,
            indicatorWeight: 3,
            labelColor: kBrandDeep,
            unselectedLabelColor: Color(0x99120A04),
            // Labelled, not icon-only: a person and a paw do not say "ranked
            // by score" and "ranked by bounty" on their own.
            tabs: [
              Tab(icon: Icon(Icons.person)),
              Tab(icon: Icon(Icons.pets)),
            ],
          ),
        ),
        body: const ContentWidth(
          child: TabBarView(children: [_UserBoard(), _BountyBoard()]),
        ),
      ),
    );
  }
}

/// Rank pill: gold/silver/bronze for the podium, a lifted chip otherwise.
Widget _rankBadge(int rank) {
  final podium = rank <= 3;
  final color = switch (rank) {
    1 => _gold,
    2 => _silver,
    3 => _bronze,
    _ => _lifted,
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
        // The medals are bright, so their number goes dark; the plain chip is
        // barely tinted, so its number goes dark too, just softer.
        color: podium ? kInk : kInk.withValues(alpha: 0.6),
      ),
    ),
  );
}

Widget _avatar({String? url, required Widget fallback, double radius = 20}) {
  return CircleAvatar(
    radius: radius,
    backgroundColor: _lifted,
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
      border: Border(bottom: BorderSide(color: _hairline)),
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
              color: kInk,
            ),
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    ),
  );
}

/// The board while it is still loading, and the single row appended while the
/// next page is fetched.
///
/// Built from the real [_rankRow] with mock values rather than hand-drawn
/// bones, so the placeholder is laid out by exactly the code that lays out the
/// loaded state and cannot drift away from it.
class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton({this.rows = 8, this.padded = false});

  final int rows;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
      physics: padded ? const NeverScrollableScrollPhysics() : null,
      shrinkWrap: padded,
      itemCount: rows,
      itemBuilder: (context, i) => _rankRow(
        // Deliberately past the podium: at ranks 1-3 the badge paints gold,
        // silver and bronze, and a placeholder has no business claiming who
        // won before the data has arrived.
        rank: i + 4,
        avatarFallback: const SizedBox.shrink(),
        title: BoneMock.name,
        trailing: const Text(
          '000',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
    return Skeletonizer(effect: AppSkeletons.onSurface, child: list);
  }
}

/// A failure the user can act on, and a way to act on it.
///
/// The raw exception is deliberately not printed: it is a transport or parsing
/// detail, and putting it on screen tells the user nothing they can use.
Widget _errorRetry(Object err, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wifi_off_rounded,
          color: kInk.withValues(alpha: 0.35),
          size: 34,
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "Couldn't load the rankings.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xB3120A04), fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: kBrandDeep),
          child: const Text('Retry'),
        ),
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

    if (state.initialLoading) return const _BoardSkeleton();
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
                  return const _BoardSkeleton(rows: 1, padded: true);
                }
                final u = state.entries[i];
                return _rankRow(
                  rank: u.rank,
                  imageUrl: u.profileImageUrl,
                  avatarFallback: Icon(
                    Icons.person,
                    size: 20,
                    color: kInk.withValues(alpha: 0.4),
                  ),
                  title: u.username,
                  trailing: Text(
                    '${u.totalScore}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _scoreGreen,
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
          // Lifted off the page rather than a different colour from it: this
          // is the same list, pinned.
          color: Colors.white,
          border: Border.all(color: kInk.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: kInk.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kBrandLight, kBrand],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
                  Text(
                    'YOUR STANDING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: kInk.withValues(alpha: 0.55),
                    ),
                  ),
                  Text(
                    me.username.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: kInk,
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
      final s = k.truncateToDouble() == k
          ? k.toStringAsFixed(0)
          : k.toStringAsFixed(1);
      return '฿${s}k';
    }
    return '฿${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bountyRankProvider);
    final notifier = ref.read(bountyRankProvider.notifier);

    if (state.initialLoading) return const _BoardSkeleton();
    if (state.error != null && state.entries.isEmpty) {
      return _errorRetry(state.error!, notifier.loadInitial);
    }
    if (state.entries.isEmpty) {
      return const Center(
        child: Text(
          'No active bounties right now.',
          style: TextStyle(color: Color(0x8C120A04)),
        ),
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
            return const _BoardSkeleton(rows: 1, padded: true);
          }
          final p = state.entries[i];
          return _rankRow(
            rank: p.rank,
            imageUrl: p.imageUrl,
            avatarFallback: Icon(
              Icons.pets,
              size: 20,
              color: kInk.withValues(alpha: 0.4),
            ),
            title: p.petName,
            trailing: Text(
              _fmt(p.bountyAmount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: kBrandDeep,
              ),
            ),
          );
        },
      ),
    );
  }
}
