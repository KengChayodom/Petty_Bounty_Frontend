// BountyRepository against a fake HTTP boundary (package:http/testing).
//
// What can go wrong here, and so what is pinned:
//   - the view's fields are mis-read, so the owner sees no QR code or the
//     hunter sees the wrong buttons;
//   - a 404 / 409 from the backend surfaces as a generic error, so the screen
//     cannot tell "not yours" from "already paid";
//   - a request carries the wrong path or body, or no token;
//   - the slip is posted before it has been uploaded.
// Feature 6 has no UTC numbers yet; they are issued in the Phase 6 test plan.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petty_bounty/src/features/bounty_payment/data/bounty_repository.dart';

Map<String, dynamic> _ownerView({Map<String, dynamic>? payment, bool unpaid = true}) => {
      'pet_id': 'p1',
      'role': 'owner',
      'pet_status': 'Found',
      'bounty_amount': 2000.0,
      'unpaid': unpaid,
      'found_at': '2026-10-08T10:00:00+00:00',
      'unpaid_referred_at': null,
      'bounty_unpaid': false,
      'hunter_id': 'h1',
      'hunter_username': 'Khun B',
      'hunter_promptpay': '0812345678',
      'payment': payment,
    };

http.Response _ok(Object data) =>
    http.Response(jsonEncode({'status': 'success', 'message': '', 'data': data}), 200,
        headers: {'content-type': 'application/json'});

void main() {
  late List<http.Request> sent;

  BountyRepository repo(http.Response Function(http.Request) respond,
      {Future<String> Function(String path)? upload}) {
    sent = [];
    final client = MockClient((r) async {
      sent.add(r);
      return respond(r);
    });
    return BountyRepository(
      client: client,
      baseUrl: 'http://api',
      authHeader: () => 'Bearer t',
      uploadSlip: upload ?? (path) async => 'http://slips/$path',
    );
  }

  group('fetchBounty', () {
    test('reads the owner view, with the hunter PromptPay number', () async {
      final r = repo((_) => _ok(_ownerView()));
      final v = await r.fetchBounty('p1');

      expect(sent.single.url.toString(), 'http://api/bounty/p1');
      expect(sent.single.headers['authorization'], 'Bearer t');
      expect(v.isOwner, isTrue);
      expect(v.unpaid, isTrue);
      expect(v.bountyAmount, 2000);
      expect(v.hunterPromptPay, '0812345678');
      expect(v.hunterUsername, 'Khun B');
      expect(v.payment, isNull);
    });

    test('reads a payment awaiting confirmation, and its dispute', () async {
      final r = repo((_) => _ok(_ownerView(unpaid: false, payment: {
            'id': 't1',
            'status': 'Pending_Verification',
            'amount': 2000,
            'slip_image_url': 'http://s/1.jpg',
            'reference_no': 'R1',
            'created_at': '2026-10-08T10:00:00+00:00',
            'disputed_at': '2026-10-08T11:00:00+00:00',
          })));
      final v = await r.fetchBounty('p1');

      expect(v.payment!.id, 't1');
      expect(v.payment!.isAwaiting, isTrue);
      expect(v.payment!.isDisputed, isTrue);
      expect(v.payment!.createdAt, DateTime.utc(2026, 10, 8, 10));
    });

    test('a 404 is BountyNotFound', () async {
      final r = repo((_) => http.Response('{"detail":"Missing pet p1 not found"}', 404));
      expect(r.fetchBounty('p1'), throwsA(isA<BountyNotFound>()));
    });
  });

  group('submitPayment', () {
    test('uploads the slip first, then posts its URL and the reference', () async {
      final r = repo((_) => _ok({'payment_id': 't1'}));
      await r.submitPayment('p1', slipPath: 'slip.jpg', referenceNo: ' R1 ');

      final req = sent.single;
      expect(req.method, 'POST');
      expect(req.url.toString(), 'http://api/bounty/p1/payment');
      expect(jsonDecode(req.body),
          {'slip_image_url': 'http://slips/slip.jpg', 'reference_no': 'R1'});
    });

    test('an empty reference is sent as null', () async {
      final r = repo((_) => _ok({'payment_id': 't1'}));
      await r.submitPayment('p1', slipPath: 'slip.jpg', referenceNo: '  ');
      expect(jsonDecode(sent.single.body)['reference_no'], isNull);
    });

    test('a failed upload posts nothing', () async {
      final r = repo((_) => _ok({}), upload: (_) async => throw Exception('storage down'));
      await expectLater(
          r.submitPayment('p1', slipPath: 'slip.jpg'), throwsException);
      expect(sent, isEmpty);
    });

    test('a 409 is BountyConflict carrying the server message', () async {
      final r = repo((_) => http.Response(
          '{"detail":"Missing pet p1 already has a payment awaiting confirmation or confirmed"}',
          409));
      await expectLater(
        r.submitPayment('p1', slipPath: 'slip.jpg'),
        throwsA(isA<BountyConflict>().having((e) => e.message, 'message',
            contains('already has a payment'))),
      );
    });
  });

  group('hunter actions', () {
    test('confirm posts the answer to the payment', () async {
      final r = repo((_) => _ok({'status': 'Verified'}));
      await r.answerPayment('t1', confirm: true);
      expect(sent.single.url.toString(), 'http://api/bounty/payments/t1/answer');
      expect(jsonDecode(sent.single.body), {'answer': 'Confirm'});
    });

    test('dispute posts Dispute', () async {
      final r = repo((_) => _ok({'disputed': true}));
      await r.answerPayment('t1', confirm: false);
      expect(jsonDecode(sent.single.body), {'answer': 'Dispute'});
    });

    test('refer unpaid posts to the report', () async {
      final r = repo((_) => _ok({'referred': true}));
      await r.referUnpaid('p1');
      expect(sent.single.url.toString(), 'http://api/bounty/p1/unpaid');
    });

    test('my bounties reads the list', () async {
      final r = repo((_) => _ok([
            {
              'pet_id': 'p1', 'pet_name': 'Mali', 'image_url': null,
              'pet_status': 'Found', 'bounty_amount': 2000,
              'found_at': '2026-10-08T10:00:00+00:00', 'unpaid_referred_at': null,
              'bounty_unpaid': false, 'payment_id': null, 'payment_status': null,
              'disputed_at': null,
            }
          ]));
      final list = await r.fetchMyBounties();
      expect(sent.single.url.toString(), 'http://api/bounty/mine');
      expect(list.single.petName, 'Mali');
      expect(list.single.paymentStatus, isNull);
    });
  });
}
