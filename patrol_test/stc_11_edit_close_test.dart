import 'support/ui.dart';

void main() {
  uiTest(
    'STC-11',
    'edits a disposable report then reopens the saved name',
    (ui) async {
      final name = ui.cfg('UI_EDIT_PET_NAME');
      final changed = ui.cfg('UI_EDIT_NEW_NAME');
      ui.disposable(name);
      ui.disposable(changed);
      await ui.owner.open(name);
      await ui.tap(find.byTooltip('Edit report'));
      final nameField = ui.key('edit-report-name');
      await ui.enter(nameField, changed);
      await ui.scrollTo(ui.text('Save Changes'));
      await ui.tapText('Save Changes');
      await ui.seeText('Changes saved successfully');
      await ui.map.returnToMap();
      await ui.owner.open(changed);
      await ui.seeText(changed);
    },
    needs: ['UI_EDIT_PET_NAME', 'UI_EDIT_NEW_NAME'],
  );
  uiTest('STC-11', 'cancels then ends a disposable search', (ui) async {
    ui.disposable(ui.cfg('UI_CLOSE_PET_NAME'));
    await ui.owner.open(ui.cfg('UI_CLOSE_PET_NAME'));
    await ui.tapText('My pet came home on its own');
    await ui.tapText('Cancel');
    await ui.seeText('Still searching');
    await ui.tapText('My pet came home on its own');
    await ui.tapText('Confirm');
    await ui.seeText('Home. The search has ended.');
    await ui.map.returnToMap();
    await ui.owner.open(ui.cfg('UI_CLOSE_PET_NAME'));
    await ui.seeText('Home. The search has ended.');
    expect(find.byTooltip('Edit report'), findsNothing);
  }, needs: ['UI_CLOSE_PET_NAME']);
}
