import 'support/ui.dart';

void main() {
  uiTest(
    'STC-17',
    'saves a profile name, reopens it and restores original fields',
    (ui) async {
      final profile = await ProfileFixture.capture(ui, 'OWNER');
      final changed = 'AUTOUI-${DateTime.now().millisecondsSinceEpoch}';
      await profile.preserving(() async {
        await ui.profilePage.edit();
        await ui.profilePage.save(changed, profile.phone);
        await ui.seeText(changed);
        await ui.profilePage.edit();
        expect(ui.profilePage.fieldValue('profile-username'), changed);
        await ui.tapText('Cancel');
      });
      await ui.seeText(profile.name);
    },
    needs: ['UI_PROFILE_JOURNAL_DIR'],
    timeout: const Duration(minutes: 2),
  );
}
