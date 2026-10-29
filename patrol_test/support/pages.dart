part of 'ui.dart';

abstract class PageObject {
  PageObject(this.ui);
  final Ui ui;
  PatrolIntegrationTester get $ => ui.$;
  WidgetTester get tester => ui.tester;
  String cfg(String name) => ui.cfg(name);
  Finder text(String value) => ui.text(value);
  Finder key(String value) => ui.key(value);
  Future<void> see(Finder f) => ui.see(f);
  Future<void> seeText(String s) => ui.seeText(s);
  Future<void> gone(Finder f) => ui.gone(f);
  Future<void> tap(Finder f) => ui.tap(f);
  Future<void> tapText(String s) => ui.tapText(s);
  Future<void> enter(Finder f, String s) => ui.enter(f, s);
  Future<void> scrollTo(Finder f) => ui.scrollTo(f);
  Future<void> permissions() => ui.permissions();
  Future<void> back() => ui.back();
  Future<void> until(bool Function() c, String d) => ui.until(c, d);
  void disposable(String name) => ui.disposable(name);
}

class AuthPage extends PageObject {
  AuthPage(super.ui);
  Future<void> signedOut() async {
    // A restored session may open Home behind a native permission dialog.
    await permissions();
    await until(
      () =>
          text('Welcome back').evaluate().isNotEmpty ||
          find.byTooltip('Profile').evaluate().isNotEmpty,
      'Login or Home Map',
    );
    if (find.byTooltip('Profile').evaluate().isNotEmpty) {
      await ui.profilePage.open();
      await ui.auth.logout();
    }
    await seeText('Welcome back');
  }

  Future<void> login(String role) async {
    await signedOut();
    await enter(key('auth-email'), cfg('UI_${role}_EMAIL'));
    await enter(key('auth-password'), cfg('UI_${role}_PASSWORD'));
    await tapText('Sign in');
    await permissions();
    await see(find.byTooltip('Profile'));
  }

  Future<void> logout() async {
    await tap(find.byTooltip('Log out'));
    await seeText('Log out?');
    await tapText('Log out');
    await seeText('Welcome back');
  }
}

class ProfilePage extends PageObject {
  ProfilePage(super.ui);
  Future<void> open() async {
    await tap(find.byTooltip('Profile'));
    await seeText('As hunter');
  }

  Future<int> stat(String keyName) async {
    final scope = key(keyName);
    await scrollTo(scope);
    final number = find.descendant(
      of: scope,
      matching: find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? ''),
      ),
    );
    await see(number);
    return int.parse(tester.widget<Text>(number).data!);
  }

  Future<void> edit() async {
    await tap(find.byTooltip('Edit profile'));
    await seeText('EDIT PROFILE');
  }

  String fieldValue(String name) =>
      tester.widget<TextField>(key(name)).controller!.text;
  Future<void> save(String name, String phone) async {
    await ui.profileJournal?.recordMutation(ProfileValues(name, phone));
    await enter(key('profile-username'), name);
    await enter(key('profile-phone'), phone);
    await tapText('Save Changes');
    await gone(text('EDIT PROFILE'));
  }
}

class HomePage extends PageObject {
  HomePage(super.ui);
  Future<void> returnToMap() async {
    if (text('REPORT SENT !').evaluate().isNotEmpty) {
      await tap(find.byIcon(Icons.home_rounded));
    }
    for (
      var i = 0;
      i < 6 && find.byTooltip('Profile').evaluate().isEmpty;
      i++
    ) {
      await back();
    }
    await see(find.byTooltip('Profile'));
  }
}

class SightingPage extends PageObject {
  SightingPage(super.ui);
  Future<void> openCamera() async {
    await tap(key('home-camera'));
    await permissions();
    await see(key('camera-gallery'));
  }

  Future<void> gallery({bool posting = false, bool slip = false}) async {
    if (posting) {
      await tap(key('post-photo'));
      await tapText('Choose from Gallery');
    } else if (!slip) {
      await tap(key('camera-gallery'));
    }
    final index = int.parse(cfg(slip ? 'UI_SLIP_INDEX' : 'UI_PHOTO_INDEX'));
    expect(index, greaterThanOrEqualTo(0));
    await $.platform.mobile.pickImageFromGallery(index: index);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> matching() async {
    await openCamera();
    await gallery();
    await see(find.byIcon(Icons.check));
    await tap(find.byIcon(Icons.check));
    await seeText('Matching Results');
  }

  Future<void> finalReview(String petName) async {
    await matching();
    await scrollTo(text(petName));
    await tapText(petName);
    await scrollTo(text('CONFIRM MATCH'));
    await tapText('CONFIRM MATCH');
    await seeText('Confirm and Send Report');
    await seeText(petName);
  }
}

class OwnerTrackerPage extends PageObject {
  OwnerTrackerPage(super.ui);
  Future<void> open(String name) async {
    await ui.profilePage.open();
    await tapText('As owner');
    await scrollTo(text(name));
    await tapText(name);
    await seeText('Sightings');
  }
}

class RewardsPage extends PageObject {
  RewardsPage(super.ui);
  Future<void> open(String name) async {
    await ui.profilePage.open();
    await scrollTo(text('Rewards'));
    await scrollTo(text(name));
    await tapText(name);
  }
}

class PostingPage extends PageObject {
  PostingPage(super.ui);
  Future<void> create(String name) async {
    disposable(name);
    await tap(find.byTooltip('Report Missing Pet'));
    await ui.sighting.gallery(posting: true);
    await see(find.byIcon(Icons.check_circle));
    await tap(find.byIcon(Icons.check_circle));
    final field = key('post-name');
    await enter(field, name);
    await scrollTo(key('post-location'));
    await tap(key('post-location'));
    await tapText('Use this location');
    await scrollTo(text('Post and alert hunters'));
    await tapText('Post and alert hunters');
    await seeText('Report successfully published');
    await ui.map.returnToMap();
    await ui.profilePage.open();
    await tapText('As owner');
    await scrollTo(text(name));
    await seeText(name);
  }
}
