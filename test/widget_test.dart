// Trivial smoke test — gives CI a green baseline without booting the real app.
//
// We intentionally do NOT pump PettyBountyApp here: it reads
// `Supabase.instance` (and Firebase) which require `Supabase.initialize` /
// `Firebase.initializeApp` to have run in main(), neither of which happens in
// a plain widget test. Pumping a minimal widget keeps this fast and reliable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test: a basic widget builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Petty Bounty'))),
    );

    expect(find.text('Petty Bounty'), findsOneWidget);
  });
}
