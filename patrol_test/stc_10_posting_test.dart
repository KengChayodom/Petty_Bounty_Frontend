import 'support/ui.dart';

void main() {
  uiTest(
    'STC-10',
    'publishes a uniquely named report and sees its owner card',
    (ui) async {
      final name = 'AUTOUI-post-${DateTime.now().microsecondsSinceEpoch}';
      await ui.posting.create(name);
      await ui.seeText('Still searching');
    },
    needs: ['UI_PHOTO_INDEX'],
  );
}
