import 'support/ui.dart';

void main() {
  uiTest(
    'STC-22',
    'shows the expected first active bounty and amount',
    (ui) async {
      await ui.tap(find.byTooltip('Leaderboard'));
      await ui.seeText('RANK LIST');
      await ui.tap(find.byType(Tab).at(1));
      final row = ui.key('rank-1-${ui.cfg('UI_RANK_FIRST_PET')}');
      await ui.see(row);
      await ui.see(
        find.descendant(
          of: row,
          matching: ui.text(ui.cfg('UI_RANK_FIRST_BOUNTY')),
        ),
      );
    },
    account: 'HUNTER',
    needs: ['UI_RANK_FIRST_PET', 'UI_RANK_FIRST_BOUNTY'],
  );
}
