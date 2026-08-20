library;

/// Domain models for Profile Screen state & history items.

enum SightingStatus { verified, waitingVerified, unmatch }

enum PostStatus { activeSearch, rescued, expired }

class HunterSightingHistoryItem {
  final String id;
  // Sightings don't carry a pet name or bounty (those belong to the matched
  // missing_pets row, which /sightings/me doesn't embed) — the AI-detected
  // species is the real, honest label available for this list.
  final String detectedSpecies;
  final String? petImageUrl;
  final SightingStatus status;
  // The hunter's declared action: 'Spotted' (just saw it) or 'Caught'
  // (rescued it — shown as "RESCUE"). Since 2026-08-21 bounty eligibility is
  // 'Caught' + the OWNER confirming it (sighting_matches.owner_status), not an
  // administrator's verification_status — so it's worth surfacing per sighting.
  final String actionType;
  // Null until a score_award exists for this sighting (i.e. not yet
  // verified/resolved) — shown as "Pending", never a made-up number.
  final int? points;
  final String sentAtFormatted;

  bool get isCaught => actionType.toLowerCase() == 'caught';

  const HunterSightingHistoryItem({
    required this.id,
    required this.detectedSpecies,
    required this.petImageUrl,
    required this.status,
    required this.actionType,
    required this.points,
    required this.sentAtFormatted,
  });
}

class OwnerPostHistoryItem {
  final String id;
  final String petName;
  final String? petImageUrl;
  final PostStatus status;
  final double bountyReward;
  final String postedAtFormatted;
  final int receivedEntriesCount;

  const OwnerPostHistoryItem({
    required this.id,
    required this.petName,
    required this.petImageUrl,
    required this.status,
    required this.bountyReward,
    required this.postedAtFormatted,
    required this.receivedEntriesCount,
  });
}
