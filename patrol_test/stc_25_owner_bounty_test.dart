import 'support/ui.dart';

void main() {
  uiTest(
    'STC-25',
    'shows the payment QR and submits a disposable test slip',
    (ui) async {
      ui.disposable(ui.cfg('UI_BOUNTY_OWNER_PET'));
      await ui.owner.open(ui.cfg('UI_BOUNTY_OWNER_PET'));
      await ui.seeText('Home. The search has ended.');
      expect(find.byTooltip('Edit report'), findsNothing);
      expect(ui.text('My pet came home on its own'), findsNothing);
      await ui.scrollTo(ui.text('Attach transfer slip'));
      await ui.see(find.bySemanticsLabel('PromptPay QR code'));
      await ui.tapText('Attach transfer slip');
      await ui.sighting.gallery(slip: true);
      await ui.seeText('Reference number (optional)');
      await ui.enter(find.byType(TextField), 'AUTOUI-test-slip');
      await ui.tapText('Send');
      await ui.seeText('Slip sent. The hunter will confirm the payment.');
      await ui.seeText(
        'Waiting for ${ui.cfg('UI_BOUNTY_HUNTER_NAME')} to confirm',
      );
    },
    needs: ['UI_BOUNTY_OWNER_PET', 'UI_BOUNTY_HUNTER_NAME', 'UI_SLIP_INDEX'],
  );
  uiTest(
    'STC-25',
    'refuses hand closure while a caught sighting awaits a decision',
    (ui) async {
      ui.disposable(ui.cfg('UI_LOCKED_PET_NAME'));
      await ui.owner.open(ui.cfg('UI_LOCKED_PET_NAME'));
      await ui.tapText('My pet came home on its own');
      await ui.tapText('Confirm');
      await ui.see(
        find.textContaining(
          'Decide the sighting that says the pet was caught before closing the report',
        ),
      );
      await ui.seeText('Still searching');
      await ui.map.returnToMap();
      await ui.owner.open(ui.cfg('UI_LOCKED_PET_NAME'));
      await ui.seeText('Still searching');
      await ui.see(find.byTooltip('Edit report'));
    },
    needs: ['UI_LOCKED_PET_NAME'],
  );
}
