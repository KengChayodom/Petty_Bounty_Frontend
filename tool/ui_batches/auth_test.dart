import 'package:flutter_test/flutter_test.dart';

import '../../patrol_test/stc_02_login_test.dart' as login;
import '../../patrol_test/stc_03_logout_test.dart' as logout;

void main() {
  group('login', login.main);
  group('logout', logout.main);
}
