import 'support/ui.dart';

void main() {
  uiTest(
    'STC-20',
    'confirms a disposable seen sighting and retains the verdict',
    (ui) async {
      ui.disposable(ui.cfg('UI_DECISION_PET_NAME'));
      await ui.owner.open(ui.cfg('UI_DECISION_PET_NAME'));
      final card = ui.key(ui.cfg('UI_DECISION_SIGHTING_ID'));
      await ui.scrollTo(card);
      await ui.tap(
        find.descendant(of: card, matching: ui.text("That's my pet")),
      );
      await ui.seeText('Sighting confirmed.');
      await ui.see(
        find.descendant(of: card, matching: ui.text('You confirmed this')),
      );
      await ui.map.returnToMap();
      await ui.owner.open(ui.cfg('UI_DECISION_PET_NAME'));
      await ui.scrollTo(card);
      await ui.see(
        find.descendant(of: card, matching: ui.text('You confirmed this')),
      );
    },
    needs: ['UI_DECISION_PET_NAME', 'UI_DECISION_SIGHTING_ID'],
  );
  uiTest(
    'STC-20',
    'cancels then confirms a disposable rescue',
    (ui) async {
      ui.disposable(ui.cfg('UI_RESCUE_PET_NAME'));
      await ui.auth.login('HUNTER');
      await ui.profilePage.open();
      final before = await ui.profilePage.stat('hunter-points');
      expect(int.parse(ui.cfg('UI_RESCUE_EXPECTED_POINTS')), greaterThan(0));
      await ui.auth.logout();
      await ui.auth.login('OWNER');
      await ui.owner.open(ui.cfg('UI_RESCUE_PET_NAME'));
      final card = ui.key(ui.cfg('UI_RESCUE_SIGHTING_ID'));
      final action = find.descendant(
        of: card,
        matching: ui.text('Confirm rescue'),
      );
      await ui.scrollTo(card);
      await ui.tap(action);
      await ui.tapText('Cancel');
      await ui.see(action);
      await ui.tap(action);
      await ui.tapText('Confirm');
      await ui.seeText('Home. The search has ended.');
      await ui.map.returnToMap();
      await ui.profilePage.open();
      await ui.auth.logout();
      await ui.auth.login('HUNTER');
      await ui.profilePage.open();
      expect(
        await ui.profilePage.stat('hunter-points'),
        before + int.parse(ui.cfg('UI_RESCUE_EXPECTED_POINTS')),
      );
    },
    needs: [
      'UI_RESCUE_PET_NAME',
      'UI_RESCUE_SIGHTING_ID',
      'UI_RESCUE_EXPECTED_POINTS',
      'UI_HUNTER_EMAIL',
      'UI_HUNTER_PASSWORD',
    ],
  );
}
