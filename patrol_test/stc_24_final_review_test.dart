import 'support/ui.dart';

void main() {
  for (final rescue in [false, true]) {
    final fixture = rescue ? 'UI_REVIEW_RESCUE_PET' : 'UI_REVIEW_SPOTTED_PET';
    uiTest(
      'STC-24',
      rescue
          ? 'sends a RESCUE report and sees caught in history'
          : 'sends a JUST SPOTTED report and sees seen in history',
      (ui) async {
        final name = ui.cfg(fixture);
        ui.disposable(name);
        await ui.profilePage.open();
        final before = await ui.profilePage.stat('hunter-sighting-count');
        await ui.map.returnToMap();
        await ui.sighting.finalReview(name);
        await ui.tapText(rescue ? 'RESCUE' : 'JUST SPOTTED');
        await ui.scrollTo(ui.text('Confirm and Send Report'));
        await ui.tapText('Confirm and Send Report');
        await ui.seeText('REPORT SENT !');
        await ui.map.returnToMap();
        await ui.profilePage.open();
        expect(await ui.profilePage.stat('hunter-sighting-count'), before + 1);
        await ui.scrollTo(ui.text('Your sightings'));
        final firstCard = find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'hunter-history-',
                  ),
            )
            .first;
        await ui.scrollTo(firstCard);
        await ui.see(
          find.descendant(
            of: firstCard,
            matching: find.textContaining(rescue ? 'caught' : 'seen'),
          ),
        );
        await ui.see(
          find.descendant(
            of: firstCard,
            matching: ui.text('Waiting for the owner'),
          ),
        );
      },
      account: 'HUNTER',
      needs: ['UI_PHOTO_INDEX', fixture],
    );
  }
}
