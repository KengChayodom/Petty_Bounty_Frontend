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
  ProfileFixture._(this.ui, this.account, this.journal, this.name, this.phone);
  final Ui ui;
  final String account;
  final ProfileJournal journal;
  final String name;
  final String phone;

  static Future<ProfileValues> _readProfile(Ui ui) async {
    await ui.profilePage.edit();
    final values = ProfileValues(
      ui.profilePage.fieldValue('profile-username'),
      ui.profilePage.fieldValue('profile-phone'),
    );
    await ui.tapText('Cancel');
    return values;
  }

  static Future<ProfileFixture> capture(Ui ui, String account) async {
    final journal = ProfileJournal(
      ui.cfg('UI_PROFILE_JOURNAL_DIR'),
      '${AppConfig.supabaseUrl}|${ui.cfg('UI_${account}_EMAIL').trim().toLowerCase()}',
    );
    await ui.profilePage.open();
    await ui.seeText(ui.cfg('UI_${account}_EMAIL'));
    if (await journal.read() != null) {
      final original = await journal.original();
      final pending = ProfileFixture._(
        ui,
        account,
        journal,
        original.name,
        original.phone,
      );
      await pending._restore();
      debugPrint('UI-PROFILE: pending snapshot recovered before new capture');
    }
    final current = await _readProfile(ui);
    if (current.name.startsWith('AUTOUI-')) {
      throw StateError(
        'Legacy automation name has no snapshot; recover its known original first',
      );
    }
    // Await durable storage before allowing the first profile mutation.
    await journal.begin(current);
    return ProfileFixture._(ui, account, journal, current.name, current.phone);
  }

  Future<void> _restore() async {
    if (ui.text('EDIT PROFILE').evaluate().isNotEmpty) {
      await ui.tapText('Cancel');
    }
    if (find.byTooltip('Edit profile').evaluate().isEmpty) {
      await ui.map.returnToMap();
      await ui.profilePage.open();
    }
    if (ui.text(ui.cfg('UI_${account}_EMAIL')).evaluate().isEmpty) {
      await ui.auth.logout();
      await ui.auth.login(account);
      await ui.profilePage.open();
    }
    final current = await _readProfile(ui);
    await journal.checkRecoverable(current);
    if (!current.matches(ProfileValues(name, phone))) {
      await ui.profilePage.edit();
      await ui.profilePage.save(name, phone);
    }
    // Reopen the actual form; a successful Save alone does not clear a journal.
    final reread = await _readProfile(ui);
    expect(
      reread.matches(ProfileValues(name, phone)),
      isTrue,
      reason: 'Original profile fields must be restored and reread',
    );
    await journal.clearAfterVerification(reread);
    debugPrint('UI-PROFILE: original fields verified; snapshot cleared');
  }

  Future<void> preserving(Future<void> Function() action) async {
    ui.profileJournal = journal;
    try {
      await action();
    } finally {
      try {
        await _restore();
      } finally {
        ui.profileJournal = null;
      }
    }
  }
}
