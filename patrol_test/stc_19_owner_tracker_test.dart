import 'support/ui.dart';

void main() {
  uiTest(
    'STC-19',
    'reads the prepared hunter card and opens its map',
    (ui) async {
      await ui.owner.open(ui.cfg('UI_TRACKER_PET_NAME'));
      await ui.scrollTo(ui.text(ui.cfg('UI_TRACKER_HUNTER_NAME')));
      await ui.seeText(ui.cfg('UI_TRACKER_HUNTER_NAME'));
      await ui.scrollTo(ui.text('View on map'));
      await ui.tapText('View on map');
      await ui.see(find.byKey(const Key('sighting-map')));
      await ui.back();
      await ui.seeText('Sightings');
    },
    needs: ['UI_TRACKER_PET_NAME', 'UI_TRACKER_HUNTER_NAME'],
  );
}
