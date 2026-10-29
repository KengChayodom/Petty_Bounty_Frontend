import 'dart:io';
import '../patrol_test/support/profile_journal.dart';

void require(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> rejects(Future<void> Function() action) async {
  var rejected = false;
  try {
    await action();
  } catch (_) {
    rejected = true;
  }
  require(rejected, 'Expected operation to preserve and reject unsafe state');
}

Future<void> main(List<String> args) async {
  if (args.isNotEmpty && args.first == '--crash-probe') {
    final journal = ProfileJournal(args[1], 'crashed-account');
    await journal.begin(const ProfileValues('Before crash', ''));
    await journal.recordMutation(const ProfileValues('AUTOUI-crashed', ''));
    exit(23); // Deliberately exit without running fixture cleanup.
  }
  final directory = await Directory.systemTemp.createTemp(
    'petty-profile-journal-',
  );
  try {
    const first = ProfileValues('Keng', '0800000000');
    const changed = ProfileValues('Chayodom', '0800000000');
    final journal = ProfileJournal(directory.path, 'test-account');
    await journal.begin(first);
    await journal.recordMutation(changed);
    final restarted = ProfileJournal(directory.path, 'test-account');
    require(
      (await restarted.original()).matches(first),
      'Restart lost baseline',
    );
    await restarted.checkRecoverable(changed);
    await rejects(() => restarted.begin(changed));
    require(
      (await restarted.original()).matches(first),
      'Pending baseline overwritten',
    );
    await rejects(() => restarted.clearAfterVerification(changed));
    require(await journal.file.exists(), 'Unverified restore deleted snapshot');
    await rejects(
      () =>
          restarted.checkRecoverable(const ProfileValues('External edit', '')),
    );
    require(await journal.file.exists(), 'Conflict deleted snapshot');
    await restarted.clearAfterVerification(first);
    require(
      !await journal.file.exists(),
      'Verified restore did not clear snapshot',
    );
    // A legitimate edit between completed rounds becomes the next baseline.
    await restarted.begin(changed);
    await restarted.recordMutation(
      const ProfileValues('AUTOUI-next', '0800000000'),
    );
    require(
      (await restarted.original()).matches(changed),
      'New baseline not captured',
    );
    await restarted.clearAfterVerification(changed);
    await journal.file.writeAsString('{broken');
    await rejects(() => restarted.begin(first));
    require(
      await journal.file.readAsString() == '{broken',
      'Corrupt evidence overwritten',
    );
    final unavailable = ProfileJournal('${directory.path}/missing', 'other');
    await rejects(() => unavailable.begin(first));
    final crashed = await Process.run(Platform.resolvedExecutable, [
      Platform.script.toFilePath(),
      '--crash-probe',
      directory.path,
    ]);
    require(crashed.exitCode == 23, 'Crash probe did not reach its mutation');
    final recovered = ProfileJournal(directory.path, 'crashed-account');
    require(
      (await recovered.original()).name == 'Before crash',
      'Process exit lost the original snapshot',
    );
    await recovered.checkRecoverable(const ProfileValues('AUTOUI-crashed', ''));
    await recovered.clearAfterVerification(
      const ProfileValues('Before crash', ''),
    );
    stdout.writeln('9 profile-journal recovery checks passed');
  } finally {
    await directory.delete(recursive: true);
  }
}
