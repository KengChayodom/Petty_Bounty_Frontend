// The pet detail request and the owner's contact details.
//
// The backend returns the owner's username, phone number and photo from
// GET /missing-pets/{id} only to a caller holding a valid token, and leaves
// them out for an anonymous one. The app used to send this request with no
// Authorization header at all, so once the backend enforces that, the detail
// screen would silently lose the owner's contact. What is pinned here is that
// the header is sent when there is a session and left off when there is not.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petty_bounty/src/features/home_map/data/repositories/missing_pet_repository_impl.dart';

void main() {
  Future<Map<String, String>> requestHeaders({String? Function()? auth}) async {
    late Map<String, String> seen;
    final client = MockClient((http.Request request) async {
      seen = request.headers;
      return http.Response('{}', 404);
    });
    final repo = MissingPetRepositoryImpl(client: client, authHeader: auth);

    // A 404 makes getMissingPet throw, which is fine: only the request matters.
    await expectLater(repo.getMissingPet('p1'), throwsException);
    return seen;
  }

  test('a signed-in user sends their token so the owner contact is returned',
      () async {
    final headers = await requestHeaders(auth: () => 'Bearer abc');
    expect(headers['authorization'], 'Bearer abc');
  });

  test('a signed-out user sends no Authorization header', () async {
    final headers = await requestHeaders(auth: () => null);
    expect(headers.containsKey('authorization'), isFalse);
  });

  test('without Supabase initialised the request is anonymous, not an error',
      () async {
    final headers = await requestHeaders();
    expect(headers.containsKey('authorization'), isFalse);
  });
}
