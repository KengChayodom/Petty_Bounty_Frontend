// Widget tests for the two sides of a bounty payment, one case per state.
//
// The repository is the seam: a fake that serves a fixed BountyView and
// records the actions. What can go wrong, and so what is pinned:
//   - the owner sees a QR code when the hunter has no PromptPay number, or the
//     card while a payment already awaits confirmation (paying twice);
//   - the hunter is offered "Not received" after the 72-hour dispute window,
//     or "Report unpaid" after its own 72-hour window, or once referred;
//   - a button calls the wrong action.
// Feature 6 has no UTC numbers yet; they are issued in the Phase 6 test plan.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/bounty_payment/data/bounty_repository.dart';
import 'package:petty_bounty/src/features/bounty_payment/data/models/bounty_models.dart';
import 'package:petty_bounty/src/features/bounty_payment/domain/providers/bounty_providers.dart';
import 'package:petty_bounty/src/features/bounty_payment/presentation/hunter_bounty_screen.dart';
import 'package:petty_bounty/src/features/bounty_payment/presentation/owner_bounty_section.dart';
import 'package:qr_flutter/qr_flutter.dart';

final _found = DateTime.utc(2026, 10, 8, 10);

class _FakeRepo implements BountyRepository {
  _FakeRepo(this.view);
  BountyView view;
  final List<String> calls = [];

  @override
  Future<BountyView> fetchBounty(String petId) async => view;
  @override
  Future<void> submitPayment(String petId, {required String slipPath, String? referenceNo}) async =>
      calls.add('submit:$slipPath:$referenceNo');
  @override
  Future<void> answerPayment(String paymentId, {required bool confirm}) async =>
      calls.add('answer:$paymentId:${confirm ? 'Confirm' : 'Dispute'}');
  @override
  Future<void> referUnpaid(String petId) async => calls.add('unpaid:$petId');
  @override
  Future<List<HunterBounty>> fetchMyBounties() async => const [];
}

BountyView _view({
  String role = 'owner',
  bool unpaid = true,
  String? promptPay = '0812345678',
  BountyPayment? payment,
  DateTime? referred,
  bool closedUnpaid = false,
  double bounty = 2000,
}) =>
    BountyView(
      petId: 'p1', role: role, petStatus: 'Found', bountyAmount: bounty,
      unpaid: unpaid, foundAt: _found, unpaidReferredAt: referred,
      bountyUnpaid: closedUnpaid, hunterUsername: 'Khun B',
      hunterPromptPay: promptPay, payment: payment,
    );

BountyPayment _payment({String status = 'Pending_Verification', DateTime? disputed}) =>
    BountyPayment(id: 't1', status: status, amount: 2000, createdAt: _found,
        disputedAt: disputed, referenceNo: 'R1');

Future<_FakeRepo> _pump(WidgetTester t, Widget child, BountyView v) async {
  final repo = _FakeRepo(v);
  await t.pumpWidget(ProviderScope(
    overrides: [bountyRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  ));
  await t.pumpAndSettle();
  return repo;
}

Widget _owner({SlipPicker? pick}) =>
    OwnerBountySection(petId: 'p1', pickSlip: pick ?? () async => 'slip.jpg');

Widget _hunter(DateTime now) =>
    SizedBox(height: 900, child: HunterBountyScreen(petId: 'p1', now: () => now));

void main() {
  group('owner', () {
    testWidgets('owing, with a PromptPay number: the QR code and the slip button', (t) async {
      await _pump(t, _owner(), _view());
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Attach transfer slip'), findsOneWidget);
    });

    testWidgets('owing, without a number: payout details awaited, no QR', (t) async {
      await _pump(t, _owner(), _view(promptPay: null));
      expect(find.byType(QrImageView), findsNothing);
      expect(find.textContaining("payout details"), findsOneWidget);
    });

    testWidgets('a payment awaiting confirmation: no card, so no second payment', (t) async {
      await _pump(t, _owner(), _view(unpaid: false, payment: _payment()));
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Waiting for Khun B to confirm'), findsOneWidget);
    });

    testWidgets('a disputed payment says so', (t) async {
      await _pump(t, _owner(), _view(unpaid: false, payment: _payment(disputed: _found)));
      expect(find.text('The hunter says the money has not arrived'), findsOneWidget);
    });

    testWidgets('a confirmed payment closes the matter', (t) async {
      await _pump(t, _owner(), _view(unpaid: false, payment: _payment(status: 'Verified')));
      expect(find.text('Bounty paid'), findsOneWidget);
    });

    testWidgets('a rejected payment shows the card again with a notice', (t) async {
      await _pump(t, _owner(), _view(payment: _payment(status: 'Rejected')));
      expect(find.text('Your last payment was rejected'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('closed as unpaid by an administrator', (t) async {
      await _pump(t, _owner(), _view(unpaid: false, closedUnpaid: true));
      expect(find.text('Closed as unpaid'), findsOneWidget);
    });

    testWidgets('no bounty renders nothing', (t) async {
      await _pump(t, _owner(), _view(unpaid: false, bounty: 0));
      expect(find.byType(QrImageView), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('attaching a slip submits it with the reference', (t) async {
      final repo = await _pump(t, _owner(), _view());
      await t.tap(find.text('Attach transfer slip'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'R9');
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(repo.calls, ['submit:slip.jpg:R9']);
    });

    testWidgets('dismissing the reference dialog cancels; nothing is sent', (t) async {
      // Regression (code review 2026-10-08): tapping outside the dialog used
      // to submit the payment as if "Skip" had been pressed.
      final repo = await _pump(t, _owner(), _view());
      await t.tap(find.text('Attach transfer slip'));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(5, 5)); // the barrier, outside the dialog
      await t.pumpAndSettle();
      expect(repo.calls, isEmpty);
    });

    testWidgets('skip submits with no reference', (t) async {
      final repo = await _pump(t, _owner(), _view());
      await t.tap(find.text('Attach transfer slip'));
      await t.pumpAndSettle();
      await t.tap(find.text('Skip'));
      await t.pumpAndSettle();
      expect(repo.calls, ['submit:slip.jpg:']);
    });

    testWidgets('cancelling the picker submits nothing', (t) async {
      final repo = await _pump(t, _owner(pick: () async => null), _view());
      await t.tap(find.text('Attach transfer slip'));
      await t.pumpAndSettle();
      expect(repo.calls, isEmpty);
    });
  });

  group('hunter', () {
    final withinWindow = _found.add(const Duration(hours: 10));
    final afterWindow = _found.add(const Duration(hours: 73));

    testWidgets('a payment within the window: confirm and not-received', (t) async {
      await _pump(t, _hunter(withinWindow), _view(role: 'hunter', unpaid: false, payment: _payment()));
      expect(find.text('I received the money'), findsOneWidget);
      expect(find.text('Not received'), findsOneWidget);
    });

    testWidgets('after the dispute window only confirming is offered', (t) async {
      await _pump(t, _hunter(afterWindow), _view(role: 'hunter', unpaid: false, payment: _payment()));
      expect(find.text('I received the money'), findsOneWidget);
      expect(find.text('Not received'), findsNothing);
    });

    testWidgets('confirming asks first, then answers Confirm', (t) async {
      final repo = await _pump(t, _hunter(withinWindow),
          _view(role: 'hunter', unpaid: false, payment: _payment()));
      await t.tap(find.text('I received the money'));
      await t.pumpAndSettle();
      await t.tap(find.text('Yes'));
      await t.pumpAndSettle();
      expect(repo.calls, ['answer:t1:Confirm']);
    });

    testWidgets('disputing answers Dispute', (t) async {
      final repo = await _pump(t, _hunter(withinWindow),
          _view(role: 'hunter', unpaid: false, payment: _payment()));
      await t.tap(find.text('Not received'));
      await t.pumpAndSettle();
      await t.tap(find.text('Yes'));
      await t.pumpAndSettle();
      expect(repo.calls, ['answer:t1:Dispute']);
    });

    testWidgets('unpaid within three days of Found: report unpaid', (t) async {
      final repo = await _pump(t, _hunter(withinWindow), _view(role: 'hunter', promptPay: null));
      await t.tap(find.text('Report unpaid'));
      await t.pumpAndSettle();
      await t.tap(find.text('Yes'));
      await t.pumpAndSettle();
      expect(repo.calls, ['unpaid:p1']);
    });

    testWidgets('unpaid after three days: no report button', (t) async {
      await _pump(t, _hunter(afterWindow), _view(role: 'hunter', promptPay: null));
      expect(find.text('Report unpaid'), findsNothing);
    });

    testWidgets('already referred: says so, no button', (t) async {
      await _pump(t, _hunter(withinWindow), _view(role: 'hunter', promptPay: null, referred: _found));
      expect(find.text('Reported as unpaid'), findsOneWidget);
      expect(find.text('Report unpaid'), findsNothing);
    });

    testWidgets('paid', (t) async {
      await _pump(t, _hunter(withinWindow),
          _view(role: 'hunter', unpaid: false, payment: _payment(status: 'Verified')));
      expect(find.text('Paid'), findsOneWidget);
    });
  });
}
