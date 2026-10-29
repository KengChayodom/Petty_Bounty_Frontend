part of 'ui.dart';

/// Real-account fixture. Missing prerequisites are skipped explicitly, never
/// converted into successful test bodies. The native orchestrator clears app
/// data between cases; restored sessions are also handled through the logout UI.
class UiFixture {
  UiFixture({required this.account, required this.needs});
  final String? account;
  final List<String> needs;
  List<String> get missing => UiConfig.missing([
    ...needs,
    if (account != null) ...['UI_${account}_EMAIL', 'UI_${account}_PASSWORD'],
  ]);
  Future<void> run(PatrolIntegrationTester tester, UiBody body) async {
    final ui = Ui(tester);
    await ui.start();
    if (account != null) await ui.auth.login(account!);
    await body(ui);
  }
}

/// Snapshot and restore through the Profile UI, including cross-account tests.
/// Register this before the first profile mutation, then call preserving().
class ProfileFixture {
  ProfileFixture._(this.ui, this.account, this.name, this.phone);
  final Ui ui;
  final String account;
  final String name;
  final String phone;
  static Future<ProfileFixture> capture(Ui ui, String account) async {
    await ui.profilePage.open();
    await ui.profilePage.edit();
    final snapshot = ProfileFixture._(
      ui,
      account,
      ui.profilePage.fieldValue('profile-username'),
      ui.profilePage.fieldValue('profile-phone'),
    );
    await ui.tapText('Cancel');
    return snapshot;
  }

  Future<void> preserving(Future<void> Function() action) async {
    try {
      await action();
    } finally {
      if (ui.text('EDIT PROFILE').evaluate().isNotEmpty) {
        await ui.tapText('Cancel');
      }
      await ui.map.returnToMap();
      await ui.profilePage.open();
      await ui.auth.logout();
      await ui.auth.login(account);
      await ui.profilePage.open();
      await ui.profilePage.edit();
      await ui.profilePage.save(name, phone);
      await ui.profilePage.edit();
      expect(ui.profilePage.fieldValue('profile-username'), name);
      expect(ui.profilePage.fieldValue('profile-phone'), phone);
      await ui.tapText('Cancel');
    }
  }
}
