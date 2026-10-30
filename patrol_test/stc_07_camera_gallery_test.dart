import 'support/ui.dart';

void main() {
  uiTest(
    'STC-07',
    'opens the native gallery and displays the selected sighting photo',
    (ui) async {
      await ui.sighting.openCamera();
      await ui.sighting.gallery();
      // Species confirmation overlays the selected photo after actual analysis.
      await ui.see(find.byIcon(Icons.check));
      await ui.see(find.byType(Dialog));
      await ui.back();
      await ui.back();
      await ui.see(ui.key('camera-gallery'));
    },
    account: 'HUNTER',
    needs: ['UI_PHOTO_INDEX'],
  );
}
