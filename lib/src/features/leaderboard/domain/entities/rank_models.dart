library;

/// One row of the user (hunter) leaderboard — `GET /leaderboard/users`.
class RankUser {
  final int rank;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final int totalScore;

  const RankUser({
    required this.rank,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.totalScore,
  });

  factory RankUser.fromJson(Map<String, dynamic> json) => RankUser(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        userId: json['user_id'] as String? ?? '',
        username: (json['username'] as String?)?.trim().isNotEmpty == true
            ? (json['username'] as String).trim()
            : 'Anonymous',
        profileImageUrl: (json['profile_image_url'] as String?)?.isNotEmpty == true
            ? json['profile_image_url'] as String
            : null,
        totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      );
}

/// One row of the bounty leaderboard — `GET /leaderboard/bounties`.
class RankBounty {
  final int rank;
  final String petId;
  final String petName;
  final String? imageUrl;
  final double bountyAmount;

  const RankBounty({
    required this.rank,
    required this.petId,
    required this.petName,
    this.imageUrl,
    required this.bountyAmount,
  });

  factory RankBounty.fromJson(Map<String, dynamic> json) => RankBounty(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        petId: json['pet_id'] as String? ?? '',
        petName: (json['pet_name'] as String?)?.trim().isNotEmpty == true
            ? (json['pet_name'] as String).trim()
            : 'Pet',
        imageUrl: (json['image_url'] as String?)?.isNotEmpty == true
            ? json['image_url'] as String
            : null,
        bountyAmount: (json['bounty_amount'] as num?)?.toDouble() ?? 0,
      );
}

/// A page of the user board plus the caller's own global standing.
class UserRankPage {
  final List<RankUser> entries;
  final RankUser? me;

  const UserRankPage({required this.entries, this.me});
}
