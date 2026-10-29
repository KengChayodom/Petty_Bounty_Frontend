import 'support/ui.dart';

void main() {
  uiTest(
    'STC-21',
    'shows the expected first hunter and score at rank one',
    (ui) async {
      await ui.tap(find.byTooltip('Leaderboard'));
      await ui.seeText('RANK LIST');
      final row = ui.key('rank-1-${ui.cfg('UI_RANK_FIRST_HUNTER')}');
      await ui.see(row);
      await ui.see(
        find.descendant(
          of: row,
          matching: ui.text(ui.cfg('UI_RANK_FIRST_POINTS')),
        ),
      );
    },
    account: 'HUNTER',
    needs: ['UI_RANK_FIRST_HUNTER', 'UI_RANK_FIRST_POINTS'],
  );
}
