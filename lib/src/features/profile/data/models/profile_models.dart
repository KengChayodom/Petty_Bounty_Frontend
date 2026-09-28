library;

/// Data models for Profile feature matching backend JSON schemas.

class ProfileUserModel {
  final String id;
  final String username;
  final String? phone;
  final String? email;
  final String role;
  final int totalScore;
  final String? profileImageUrl;

  const ProfileUserModel({
    required this.id,
    required this.username,
    this.phone,
    this.email,
    required this.role,
    required this.totalScore,
    this.profileImageUrl,
  });

  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'User',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'user',
      totalScore: json['total_score'] as int? ?? 0,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}

class HunterStatsModel {
  final int totalScore;
  final int sightingsSubmitted;
  final int sightingsVerified;
  final int resolutionsContributedTo;

  const HunterStatsModel({
    required this.totalScore,
    required this.sightingsSubmitted,
    required this.sightingsVerified,
    required this.resolutionsContributedTo,
  });

  factory HunterStatsModel.fromJson(Map<String, dynamic> json) {
    return HunterStatsModel(
      totalScore: json['total_score'] as int? ?? 0,
      sightingsSubmitted: json['sightings_submitted'] as int? ?? 0,
      sightingsVerified: json['sightings_verified'] as int? ?? 0,
      resolutionsContributedTo: json['resolutions_contributed_to'] as int? ?? 0,
    );
  }
}
