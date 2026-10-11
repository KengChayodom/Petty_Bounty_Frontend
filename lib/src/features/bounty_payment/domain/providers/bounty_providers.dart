import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/bounty_repository.dart';
import '../entities/bounty_models.dart';

/// DI seam for the bounty repository (overridable in tests).
final bountyRepositoryProvider =
    Provider<BountyRepository>((ref) => BountyRepository());

/// The payment state of one closed report, keyed by pet id. autoDispose and
/// invalidated after every action, so the screen always shows the server's
/// answer rather than a local guess.
final bountyViewProvider =
    FutureProvider.autoDispose.family<BountyView, String>((ref, petId) {
  return ref.watch(bountyRepositoryProvider).fetchBounty(petId);
});

/// The reports the signed-in user returned the pet for.
final myBountiesProvider =
    FutureProvider.autoDispose<List<HunterBounty>>((ref) {
  return ref.watch(bountyRepositoryProvider).fetchMyBounties();
});
