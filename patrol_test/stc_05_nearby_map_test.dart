import 'support/ui.dart';

void main() {
  uiTest(
    'STC-05',
    'shows a prepared nearby marker and recentres the map',
    (ui) async {
      await ui.see(ui.key('pet-marker-${ui.cfg('UI_NEARBY_PET_ID')}'));
      await ui.tap(find.byTooltip('Recentre on me'));
      await ui.see(ui.key('pet-marker-${ui.cfg('UI_NEARBY_PET_ID')}'));
      await ui.tap(ui.key('pet-marker-${ui.cfg('UI_NEARBY_PET_ID')}'));
      await ui.seeText(ui.cfg('UI_NEARBY_PET_NAME'));
    },
    account: 'HUNTER',
    needs: ['UI_NEARBY_PET_ID', 'UI_NEARBY_PET_NAME'],
  );
}
