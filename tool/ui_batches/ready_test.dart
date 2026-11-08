import 'package:flutter_test/flutter_test.dart';

import '../../patrol_test/stc_02_login_test.dart' as login;
import '../../patrol_test/stc_03_logout_test.dart' as logout;
import '../../patrol_test/stc_17_profile_test.dart' as profile;

// Explicit entrypoint: reuses the existing four scenarios without adding cases.
void main() {
  group('login', login.main);
  group('logout', logout.main);
  group('profile', profile.main);
}
