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
      debugPrint('UI-STC03: back completed');
      await ui.$.platform.mobile.pressHome();
      await ui.$.platform.mobile.openApp(appId: 'com.pettybounty.app');
      debugPrint('UI-STC03: app activated');
      await ui.seeText('Welcome back');
      expect(find.byTooltip('Profile'), findsNothing);
      debugPrint('UI-STC03: signed-out assertions completed');
    },
    timeout: const Duration(minutes: 2),
  );
}
