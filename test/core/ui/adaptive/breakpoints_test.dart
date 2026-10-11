import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/core/ui/adaptive/breakpoints.dart';

void main() {
  group('WindowSize.fromWidth', () {
    test('phones are compact', () {
      expect(WindowSize.fromWidth(390), WindowSize.compact);
      expect(WindowSize.fromWidth(599.9), WindowSize.compact);
    });

    test('iPad portrait and split view are medium', () {
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(820), WindowSize.medium);
    });

    test('iPad landscape is expanded', () {
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
      expect(WindowSize.fromWidth(1194), WindowSize.expanded);
    });
  });

  group('ContentWidth', () {
    Future<double> widthAt(WidgetTester tester, double screenWidth) async {
      tester.view.physicalSize = Size(screenWidth, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: ContentWidth(child: SizedBox(key: Key('box'), width: double.infinity, height: 10)),
        ),
      );
      return tester.getSize(find.byKey(const Key('box'))).width;
    }

    testWidgets('leaves a phone at full width', (tester) async {
      expect(await widthAt(tester, 390), 390);
    });

    testWidgets('caps an iPad-wide window', (tester) async {
      expect(await widthAt(tester, 1024), kContentMaxWidth);
    });
  });
}
