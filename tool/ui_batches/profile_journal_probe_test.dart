import '../../patrol_test/support/profile_journal.dart';
import '../../patrol_test/support/ui.dart';

// Infrastructure probe only; this does not mutate a profile or add STC coverage.
void main() {
  uiTest(
    'INFRA',
    'verifies host profile-journal persistence',
    (ui) async {
      final journal = ProfileJournal(
        ui.cfg('UI_PROFILE_JOURNAL_DIR'),
        'storage-probe',
      );
      const original = ProfileValues('storage-probe-original', '');
      if (await journal.read() == null) await journal.begin(original);
      await journal.recordMutation(
        const ProfileValues('storage-probe-change', ''),
      );
      final reopened = ProfileJournal(
        ui.cfg('UI_PROFILE_JOURNAL_DIR'),
        'storage-probe',
      );
      expect((await reopened.original()).matches(original), isTrue);
      await reopened.clearAfterVerification(original);
      debugPrint(
        'UI-JOURNAL: host persistence verified without profile mutation',
      );
    },
    account: null,
    needs: ['UI_PROFILE_JOURNAL_DIR'],
  );
}
