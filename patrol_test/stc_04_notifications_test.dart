import 'support/ui.dart';

void main() {
  uiTest(
    'STC-04',
    'receives a new nearby report notification and opens that pet',
    (ui) async {
      // On a second device, the owner publishes a NEW uniquely named report
      // through the app after this watcher starts. Never synthesize an FCM push.
      final expected = ui.cfg('UI_NOTIFICATION_TEXT');
      await ui.$.platform.mobile.pressHome();
      await ui.$.platform.mobile.openNotifications();
      var notifications = await ui.$.platform.mobile.getNotifications();
      expect(
        notifications.any((n) => '${n.title} ${n.content}'.contains(expected)),
        isFalse,
        reason:
            'Use a unique report name; an old notification is not fresh delivery',
      );
      final clock = Stopwatch()..start();
      while (!notifications.any(
            (n) => '${n.title} ${n.content}'.contains(expected),
          ) &&
          clock.elapsed < const Duration(minutes: 2)) {
        await Future<void>.delayed(const Duration(seconds: 2));
        notifications = await ui.$.platform.mobile.getNotifications();
      }
      final index = notifications.indexWhere(
        (n) => '${n.title} ${n.content}'.contains(expected),
      );
      expect(
        index,
        greaterThanOrEqualTo(0),
        reason: 'New notification within two minutes',
      );
      await ui.$.platform.mobile.tapOnNotificationByIndex(index);
      await ui.seeText(ui.cfg('UI_NOTIFICATION_PET_NAME'));
    },
    account: 'HUNTER',
    needs: ['UI_NOTIFICATION_TEXT', 'UI_NOTIFICATION_PET_NAME'],
  );
}
