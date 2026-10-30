import 'dart:convert';
import 'dart:io';

class ProfileValues {
  const ProfileValues(this.name, this.phone);
  final String name;
  final String phone;
  Map<String, String> toJson() => {'name': name, 'phone': phone};
  factory ProfileValues.fromJson(Map<String, dynamic> value) =>
      ProfileValues(value['name'] as String, value['phone'] as String);
  bool matches(ProfileValues other) =>
      name == other.name && phone == other.phone;
}

/// Private host-mounted journal. The caller must verify UI values before clear.
/// No fallback to app storage: uninstalling a test app must not lose a snapshot.
class ProfileJournal {
  ProfileJournal(String directory, this.accountKey)
    : file = File(
        '$directory/${base64Url.encode(utf8.encode(accountKey)).replaceAll('=', '')}.json',
      ) {
    if (directory.isEmpty || !Directory(directory).isAbsolute) {
      throw StateError('An absolute UI_PROFILE_JOURNAL_DIR is required');
    }
  }
  final String accountKey;
  final File file;

  Future<Map<String, dynamic>?> read() async {
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (data['version'] != 1 || data['account'] != accountKey) {
      throw StateError('Invalid profile journal; preserve it for recovery');
    }
    ProfileValues.fromJson(data['original'] as Map<String, dynamic>);
    for (final value in data['mutations'] as List<dynamic>) {
      ProfileValues.fromJson(value as Map<String, dynamic>);
    }
    return data;
  }

  Future<void> begin(ProfileValues original) async {
    if (await read() != null) {
      throw StateError('Recover the pending profile snapshot first');
    }
    // Exclusive creation prevents two runners from replacing the same baseline.
    await file.create(exclusive: true);
    await file.writeAsString(
      jsonEncode({
        'version': 1,
        'account': accountKey,
        'original': original.toJson(),
        'mutations': <Map<String, String>>[],
      }),
      flush: true,
    );
  }

  Future<ProfileValues> original() async {
    final data = await read();
    if (data == null) throw StateError('Profile snapshot is missing');
    return ProfileValues.fromJson(data['original'] as Map<String, dynamic>);
  }

  Future<void> recordMutation(ProfileValues value) async {
    final data = await read();
    if (data == null) {
      throw StateError('Snapshot must be saved before mutation');
    }
    final baseline = ProfileValues.fromJson(
      data['original'] as Map<String, dynamic>,
    );
    if (value.matches(baseline)) return;
    (data['mutations'] as List<dynamic>).add(value.toJson());
    final temporary = File('${file.path}.pending');
    await temporary.writeAsString(jsonEncode(data), flush: true);
    await temporary.rename(file.path);
  }

  Future<void> checkRecoverable(ProfileValues current) async {
    final data = await read();
    if (data == null) throw StateError('Profile snapshot is missing');
    final known = [data['original'], ...(data['mutations'] as List<dynamic>)];
    if (!known.any(
      (v) => ProfileValues.fromJson(v as Map<String, dynamic>).matches(current),
    )) {
      throw StateError(
        'Profile changed outside this run; keep snapshot and resolve conflict',
      );
    }
  }

  Future<void> clearAfterVerification(ProfileValues reread) async {
    if (!reread.matches(await original())) {
      throw StateError(
        'Profile restoration is not verified; snapshot retained',
      );
    }
    await file.delete();
  }
}
