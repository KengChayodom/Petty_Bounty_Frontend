import 'support/ui.dart';

void main() {
  uiTest(
    'STC-09',
    'selects the expected candidate and enters final review',
    (ui) async {
      await ui.sighting.finalReview(ui.cfg('UI_MATCH_PET_NAME'));
      await ui.seeText('JUST SPOTTED');
      await ui.seeText('RESCUE');
    },
    account: 'HUNTER',
    needs: ['UI_PHOTO_INDEX', 'UI_MATCH_PET_NAME'],
  );
}
