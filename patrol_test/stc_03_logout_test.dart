import 'support/ui.dart';

void main() {
  uiTest(
    'STC-03',
    'cancels logout then logs out and cannot return through Back',
    (ui) async {
      await ui.profilePage.open();
      await ui.tap(find.byTooltip('Log out'));
      await ui.tapText('Cancel');
      await ui.seeText('As hunter');
      await ui.auth.logout();
      await ui.back();
      await ui.$.platform.mobile.openApp();
      await ui.seeText('Welcome back');
      expect(find.byTooltip('Profile'), findsNothing);
    },
  );
}
