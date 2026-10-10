/// Typed request body for `POST /missing-pets/` (`MissingPetCreate` on the
/// backend, see Petty_Bounty_Backend/app/schemas/missing_pets.py). Building
/// this from named, typed fields instead of a raw `Map<String, dynamic>`
/// catches a mistyped key or wrong value type at compile time.
class LostPetPostRequest {
  final String petName;
  final String species;
  final Map<String, dynamic> characteristics;
  final double bountyAmount;
  final double latitude;
  final double longitude;
  final DateTime lastSeenTime;
  final String imageUrl;
  final String? primaryColorHex;

  const LostPetPostRequest({
    required this.petName,
    required this.species,
    required this.characteristics,
    required this.bountyAmount,
    required this.latitude,
    required this.longitude,
    required this.lastSeenTime,
    required this.imageUrl,
    this.primaryColorHex,
  });

  Map<String, dynamic> toJson() => {
        'pet_name': petName,
        'species': species,
        'characteristics': characteristics,
        'bounty_amount': bountyAmount,
        'longitude': longitude,
        'latitude': latitude,
        // .toUtc() first: a naive local DateTime's toIso8601String() carries
        // no offset/'Z' suffix, which is timezone-ambiguous to the backend.
        'last_seen_time': lastSeenTime.toUtc().toIso8601String(),
        'image_url': imageUrl,
        'primary_color_hex': primaryColorHex,
      };
}
