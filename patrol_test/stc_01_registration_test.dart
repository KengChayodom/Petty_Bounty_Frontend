import 'support/ui.dart';

void main() {
  uiTest(
    'STC-01',
    'registers a new disposable account and reads its profile',
    (ui) async {
      ui.disposable(ui.cfg('UI_REGISTER_NAME'));
      await ui.auth.signedOut();
      await ui.tapText('Register');
      for (final entry in {
        'username': 'UI_REGISTER_NAME',
        'email': 'UI_REGISTER_EMAIL',
        'phone': 'UI_REGISTER_PHONE',
        'password': 'UI_REGISTER_PASSWORD',
        'confirm-password': 'UI_REGISTER_PASSWORD',
      }.entries) {
        await ui.enter(ui.key('auth-${entry.key}'), ui.cfg(entry.value));
      }
      await ui.tapText('Register');
      await ui.permissions();
      await ui.see(find.byTooltip('Profile'));
      await ui.profilePage.open();
      await ui.seeText(ui.cfg('UI_REGISTER_NAME'));
      await ui.seeText(ui.cfg('UI_REGISTER_EMAIL'));
      await ui.seeText('${ui.cfg('UI_REGISTER_PHONE')}, used for PromptPay');
    },
    account: null,
    needs: [
      'UI_REGISTER_NAME',
      'UI_REGISTER_EMAIL',
      'UI_REGISTER_PHONE',
      'UI_REGISTER_PASSWORD',
    ],
  );
}
