import 'support/ui.dart';

void main() {
  uiTest(
    'STC-06',
    'opens and dismisses the selected pet details',
    (ui) async {
      final marker = ui.key('pet-marker-${ui.cfg('UI_NEARBY_PET_ID')}');
      await ui.tap(marker);
      await ui.seeText(ui.cfg('UI_NEARBY_PET_NAME'));
      await ui.seeText('Last seen');
      await ui.seeText('Reward');
      await ui.tapText('Close');
      await ui.gone(ui.text(ui.cfg('UI_NEARBY_PET_NAME')));
      await ui.see(marker);
    },
    account: 'HUNTER',
    needs: ['UI_NEARBY_PET_ID', 'UI_NEARBY_PET_NAME'],
  );
  uiTest(
    'STC-06',
    'sends a targeted sighting and reads it on the owner tracker',
    (ui) async {
      final name = ui.cfg('UI_TARGET_PET_NAME');
      ui.disposable(name);
      await ui.auth.login('OWNER');
      await ui.owner.open(name);
      await ui.seeText('No sightings reported yet');
      await ui.map.returnToMap();
      await ui.profilePage.open();
      await ui.auth.logout();
      await ui.auth.login('HUNTER');
      await ui.tap(ui.key('pet-marker-${ui.cfg('UI_TARGET_PET_ID')}'));
      await ui.seeText(name);
      await ui.tapText('Report Sighting');
      await ui.permissions();
      await ui.sighting.gallery();
      await ui.seeText('Send sighting?');
      await ui.tapText('Send');
      await ui.seeText('REPORT SENT !');
      await ui.map.returnToMap();
      await ui.profilePage.open();
      await ui.auth.logout();
      await ui.auth.login('OWNER');
      await ui.owner.open(name);
      await ui.scrollTo(ui.text(ui.cfg('UI_TARGET_HUNTER_NAME')));
      await ui.seeText(ui.cfg('UI_TARGET_HUNTER_NAME'));
    },
    account: 'HUNTER',
    needs: [
      'UI_TARGET_PET_ID',
      'UI_TARGET_PET_NAME',
      'UI_TARGET_HUNTER_NAME',
      'UI_PHOTO_INDEX',
      'UI_OWNER_EMAIL',
      'UI_OWNER_PASSWORD',
    ],
  );
}
