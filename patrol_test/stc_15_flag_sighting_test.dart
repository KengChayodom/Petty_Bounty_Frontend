import 'support/ui.dart';

void main() {
  uiTest(
    'STC-15',
    'flags the specified disposable sighting and keeps it visible',
    (ui) async {
      ui.disposable(ui.cfg('UI_FLAG_PET_NAME'));
      await ui.owner.open(ui.cfg('UI_FLAG_PET_NAME'));
      final card = ui.key(ui.cfg('UI_FLAG_SIGHTING_ID'));
      await ui.scrollTo(card);
      await ui.tap(
        find.descendant(of: card, matching: find.byIcon(Icons.flag_rounded)),
      );
      await ui.seeText('Report this sighting');
      await ui.tapText('Spam');
      await ui.seeText('Reported for review. Our moderators will take a look.');
      await ui.see(card);
    },
    needs: ['UI_FLAG_PET_NAME', 'UI_FLAG_SIGHTING_ID'],
  );
}
