import 'support/ui.dart';

void main() {
  for (final confirm in [true, false]) {
    final fixture = confirm ? 'UI_BOUNTY_CONFIRM_PET' : 'UI_BOUNTY_DISPUTE_PET';
    uiTest(
      'STC-26',
      confirm
          ? 'confirms a disposable payment after cancellation'
          : 'disputes a disposable payment within its window',
      (ui) async {
        ui.disposable(ui.cfg(fixture));
        await ui.rewards.open(ui.cfg(fixture));
        await ui.scrollTo(
          ui.text(confirm ? 'The money arrived' : 'It did not arrive'),
        );
        await ui.tapText(confirm ? 'The money arrived' : 'It did not arrive');
        await ui.tapText('Cancel');
        await ui.tapText(confirm ? 'The money arrived' : 'It did not arrive');
        await ui.tapText('Yes');
        await ui.seeText(
          confirm ? 'Payment confirmed.' : 'Sent to an administrator.',
        );
        await ui.seeText(
          confirm ? 'Paid' : 'You reported the money has not arrived',
        );
      },
      account: 'HUNTER',
      needs: [fixture],
    );
  }
  uiTest(
    'STC-26',
    'hides dispute on a naturally aged payment',
    (ui) async {
      await ui.rewards.open(ui.cfg('UI_BOUNTY_AGED_PET'));
      await ui.scrollTo(ui.text('The money arrived'));
      await ui.seeText('The money arrived');
      expect(ui.text('It did not arrive'), findsNothing);
    },
    account: 'HUNTER',
    needs: ['UI_BOUNTY_AGED_PET'],
  );
  uiTest(
    'STC-26',
    'a valid profile phone enables the owner payment card',
    (ui) async {
      // The owner fixture must be Found and owe THIS returning hunter, without a slip.
      final phone = ui.cfg('UI_PROMPTPAY_PHONE');
      expect(RegExp(r'^0[689][0-9]{8}$').hasMatch(phone), isTrue);
      ui.disposable(ui.cfg('UI_PROMPTPAY_PET'));
      final profile = await ProfileFixture.capture(ui, 'HUNTER');
      await profile.preserving(() async {
        // First observe that missing profile phone prevents the owner QR.
        await ui.profilePage.edit();
        await ui.profilePage.save(profile.name, '');
        await ui.auth.logout();
        await ui.auth.login('OWNER');
        await ui.owner.open(ui.cfg('UI_PROMPTPAY_PET'));
        await ui.scrollTo(ui.text("Waiting for the hunter's payout details"));
        await ui.seeText("Waiting for the hunter's payout details");
        expect(find.bySemanticsLabel('PromptPay QR code'), findsNothing);
        await ui.map.returnToMap();
        await ui.profilePage.open();
        await ui.auth.logout();
        await ui.auth.login('HUNTER');
        await ui.profilePage.open();
        await ui.profilePage.edit();
        await ui.profilePage.save(profile.name, phone);
        await ui.seeText('$phone, used for PromptPay');
        await ui.auth.logout();
        await ui.auth.login('OWNER');
        await ui.owner.open(ui.cfg('UI_PROMPTPAY_PET'));
        await ui.scrollTo(ui.text('Attach transfer slip'));
        await ui.see(find.bySemanticsLabel('PromptPay QR code'));
        // Decoding the displayed QR remains necessary to prove the encoded
        // digits, beyond this visible missing-number / available-QR flow.
      });
    },
    account: 'HUNTER',
    needs: [
      'UI_OWNER_EMAIL',
      'UI_OWNER_PASSWORD',
      'UI_PROFILE_JOURNAL_DIR',
      'UI_PROMPTPAY_PHONE',
      'UI_PROMPTPAY_PET',
    ],
  );
}
