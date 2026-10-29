import 'support/ui.dart';

void main() {
  uiTest(
    'STC-18',
    'shows hunter statistics and the prepared sighting verdict',
    (ui) async {
      await ui.profilePage.open();
      await ui.seeText('Points');
      await ui.seeText('Sightings');
      await ui.seeText('Pets home');
      final card = ui.key('hunter-history-${ui.cfg('UI_HISTORY_SIGHTING_ID')}');
      await ui.scrollTo(card);
      await ui.see(
        find.descendant(
          of: card,
          matching: ui.text(ui.cfg('UI_HISTORY_ACTION')),
        ),
      );
      await ui.see(
        find.descendant(
          of: card,
          matching: ui.text(ui.cfg('UI_HISTORY_VERDICT')),
        ),
      );
    },
    account: 'HUNTER',
    needs: [
      'UI_HISTORY_SIGHTING_ID',
      'UI_HISTORY_ACTION',
      'UI_HISTORY_VERDICT',
    ],
  );
}
