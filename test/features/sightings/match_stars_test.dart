// The stars on a match card.
//
// The list is ordered by the identity model, but the app used to draw stars from
// `similarity`, the CLIP cosine, which is on another scale. A card could sit
// above another and show fewer stars (a 2-star card ahead of a 3-star one). The
// backend now sends its own rating, `match_stars`, computed from the score that
// ordered the list, and the app draws exactly that. The old rule on `similarity`
// is kept only for a backend that does not send it.

import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/sightings/data/models/match_model.dart';

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
  group('the backend rating is what is drawn', () {
    test('a low CLIP score does not lower a card the backend rated 3', () {
      expect(_match(similarity: 0.5, stars: 3).stars, 3);
    });

    test('a high CLIP score does not raise a card the backend rated 1', () {
      expect(_match(similarity: 0.99, stars: 1).stars, 1);
    });

    test('two cards in list order can never be drawn with rising stars', () {
      // The reported case: CLIP prefers the second card, the ranking prefers
      // the first. Drawn from the rating, the first is not below the second.
      final first = _match(similarity: 0.85, stars: 3);
      final second = _match(similarity: 0.95, stars: 2);
      expect(first.stars >= second.stars, isTrue);
    });

    test('a rating outside 1 to 3 is clamped rather than drawn', () {
      expect(_match(stars: 0).stars, 1);
      expect(_match(stars: 7).stars, 3);
    });

    test('match_stars is read from the response', () {
      expect(_match(stars: 2).matchStars, 2);
    });
  });

  group('a backend without match_stars keeps the old rule on similarity', () {
    test('at and above 0.9 is 3, at and above 0.7 is 2, below is 1', () {
      expect(_match(similarity: 0.9).stars, 3);
      expect(_match(similarity: 0.8999).stars, 2);
      expect(_match(similarity: 0.7).stars, 2);
      expect(_match(similarity: 0.6999).stars, 1);
    });

    test('the field is simply null', () {
      expect(_match().matchStars, isNull);
    });
  });
}
