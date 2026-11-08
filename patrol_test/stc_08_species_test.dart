import 'support/ui.dart';

void main() {
  uiTest(
    'STC-08',
    'corrects the detected species before matching',
    (ui) async {
      await ui.sighting.openCamera();
      await ui.sighting.gallery();
      await ui.see(find.byIcon(Icons.check));
      await ui.tap(find.byIcon(Icons.close));
      await ui.seeText('Select the correct species:');
      await ui.tapText('Select species');
      await ui.tapText('Cat');
      await ui.tapText('Confirm');
      await ui.seeText('Matching Results');
    },
    account: 'HUNTER',
    needs: ['UI_PHOTO_INDEX'],
  );
}
