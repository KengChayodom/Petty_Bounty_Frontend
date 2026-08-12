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
  final String caseId;
  final String? petImageUrl;
  final SightingStatus status;
  // Null until a score_award exists for this sighting (i.e. not yet
  // verified/resolved) — shown as "Pending", never a made-up number.
  final int? points;
  final String sentAtFormatted;

  const HunterSightingHistoryItem({
    required this.id,
    required this.detectedSpecies,
    required this.caseId,
    required this.petImageUrl,
    required this.status,
    required this.points,
    required this.sentAtFormatted,
  });
}

class OwnerPostHistoryItem {
  final String id;
  final String petName;
  final String caseId;
  final String? petImageUrl;
  final PostStatus status;
  final double bountyReward;
  final String postedAtFormatted;
  final int receivedEntriesCount;

  const OwnerPostHistoryItem({
    required this.id,
    required this.petName,
    required this.caseId,
    required this.petImageUrl,
    required this.status,
    required this.bountyReward,
    required this.postedAtFormatted,
    required this.receivedEntriesCount,
  });
}
