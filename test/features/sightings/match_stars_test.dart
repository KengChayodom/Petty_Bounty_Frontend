// The stars on a match card.
//
// The list is ordered by the identity model, but the app used to draw stars from
// `similarity`, the CLIP cosine, which is on another scale. A card could sit
// above another and show fewer stars (a 2-star card ahead of a 3-star one). The
// backend now sends its own rating, `match_stars`, computed from the score that
// ordered the list, and the app draws exactly that. The old rule on `similarity`
// is kept only for a backend that does not send it.

import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/sightings/domain/entities/match_model.dart';

Map<String, dynamic> _json({double similarity = 0.5, Object? stars}) => {
  'id': 'p1',
  'pet_name': 'Mochi',
  'species': 'Cat',
  'characteristics': <String, dynamic>{},
  'bounty_amount': 100.0,
  'last_seen_location': 'POINT(100 13)',
  'last_seen_time': '2026-09-01T10:00:00Z',
  'image_url': 'https://x/p.jpg',
  'similarity': similarity,
  'distance_meters': 120.0,
  'status': 'Searching',
  'match_stars': ?stars,
};

MatchModel _match({double similarity = 0.5, Object? stars}) =>
    MatchModel.fromJson(_json(similarity: similarity, stars: stars));

void main() {
  group('MatchModel.stars', () {
    test(
      'TC-01 a backend rating wins over similarity and is held to 1 to 3',
      () {
        // Similarity alone would give 1 star. The rating of 7 is drawn as 3.
        expect(_match(similarity: 0.5, stars: 7).stars, 3);
      },
    );

    test('TC-02 no rating and similarity at 0.9 gives 3 stars', () {
      expect(_match(similarity: 0.9).stars, 3);
    });

    test('TC-03 no rating and similarity at 0.7 gives 2 stars', () {
      expect(_match(similarity: 0.7).stars, 2);
    });

    test('TC-04 no rating and similarity below 0.7 gives 1 star', () {
      expect(_match(similarity: 0.6999).stars, 1);
    });
  });
}
