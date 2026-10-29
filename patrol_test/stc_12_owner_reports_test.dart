import 'support/ui.dart';

void main() {
  uiTest(
    'STC-12',
    'switches to owner reports and opens the prepared report',
    (ui) async {
      await ui.profilePage.open();
      await ui.tapText('As owner');
      await ui.seeText('Your reports');
      await ui.scrollTo(ui.text(ui.cfg('UI_OWNER_REPORT_NAME')));
      await ui.tapText(ui.cfg('UI_OWNER_REPORT_NAME'));
      await ui.seeText('Sightings');
      await ui.seeText(ui.cfg('UI_OWNER_REPORT_NAME'));
    },
    needs: ['UI_OWNER_REPORT_NAME'],
  );
}
