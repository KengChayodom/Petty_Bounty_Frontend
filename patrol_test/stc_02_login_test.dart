import 'support/ui.dart';

void main() {
  uiTest(
    'STC-02',
    'shows the login form and validates an empty submission',
    (ui) async {
      await ui.auth.signedOut();
      await ui.seeText('Welcome back');
      await ui.see(ui.key('auth-email'));
      await ui.see(ui.key('auth-password'));
      await ui.tapText('Sign in');
      await ui.seeText('Email is required!');
    },
    account: null,
  );

  uiTest(
    'STC-02',
    'rejects a wrong password then signs in to the correct profile',
    (ui) async {
      await ui.auth.signedOut();
      await ui.enter(ui.key('auth-email'), ui.cfg('UI_OWNER_EMAIL'));
      await ui.enter(ui.key('auth-password'), 'invalid-automation-password');
      await ui.tapText('Sign in');
      await ui.seeText('Invalid email or password');
      await ui.enter(ui.key('auth-password'), ui.cfg('UI_OWNER_PASSWORD'));
      await ui.tapText('Sign in');
      await ui.permissions();
      await ui.see(find.byTooltip('Profile'));
      await ui.profilePage.open();
      await ui.seeText(ui.cfg('UI_OWNER_EMAIL'));
    },
    account: null,
    needs: ['UI_OWNER_EMAIL', 'UI_OWNER_PASSWORD'],
  );
}
