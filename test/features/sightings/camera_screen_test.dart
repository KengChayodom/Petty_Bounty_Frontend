// Widget tests for CameraScreen's three startup branches:
//   - has camera        -> live preview + shutter button
//   - no camera         -> "ไม่พบกล้อง" fallback (e.g. iOS Simulator)
//   - permission denied -> "ไม่ได้รับสิทธิ์ใช้กล้อง" fallback
//
// We never touch a real camera: CameraScreen exposes an [initializer] seam that
// returns a CameraSetupResult, and a [previewBuilder] seam so the "ready" UI can
// render without a platform-backed controller.

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/sightings/presentation/camera_screen.dart';

// A controller that is never initialize()'d — its dispose() does not call the
// platform, so it is safe to construct and tear down in a widget test.
CameraController _uninitializedController() => CameraController(
  const CameraDescription(
    name: 'fake',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 0,
  ),
  ResolutionPreset.low,
  enableAudio: false,
);

Future<void> _pumpCamera(
  WidgetTester tester, {
  required CameraInitializer initializer,
  CameraPreviewBuilder? previewBuilder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CameraScreen(
        initializer: initializer,
        previewBuilder: previewBuilder,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CameraScreen', () {
    testWidgets('has camera -> shows preview + shutter, no fallback text', (
      tester,
    ) async {
      final controller = _uninitializedController();
      addTearDown(controller.dispose);

      await _pumpCamera(
        tester,
        initializer: () async =>
            CameraSetupResult(CameraSetupStatus.ready, controller: controller),
        // Avoid building the real CameraPreview (needs a platform texture).
        previewBuilder: (_) => const SizedBox.expand(),
      );

      expect(find.byKey(const Key('camera_ready')), findsOneWidget);
      expect(find.byKey(const Key('camera_shutter')), findsOneWidget);
      // Gallery button (its icon) is present.
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      // No fallback messaging on the happy path.
      expect(find.text('ไม่พบกล้อง'), findsNothing);
      expect(find.text('ไม่ได้รับสิทธิ์ใช้กล้อง'), findsNothing);
    });

    testWidgets('no camera -> "ไม่พบกล้อง" fallback with gallery, no shutter', (
      tester,
    ) async {
      await _pumpCamera(
        tester,
        initializer: () async =>
            const CameraSetupResult(CameraSetupStatus.unavailable),
      );

      expect(find.byKey(const Key('camera_no_camera')), findsOneWidget);
      expect(find.text('ไม่พบกล้อง'), findsOneWidget);
      // Gallery button stays at the bottom-left so the user can still pick.
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      // No shutter, no live-camera scaffold.
      expect(find.byKey(const Key('camera_shutter')), findsNothing);
      expect(find.byKey(const Key('camera_ready')), findsNothing);
    });

    testWidgets(
      'permission denied -> "ไม่ได้รับสิทธิ์ใช้กล้อง" fallback with gallery',
      (tester) async {
        await _pumpCamera(
          tester,
          initializer: () async =>
              const CameraSetupResult(CameraSetupStatus.permissionDenied),
        );

        expect(
          find.byKey(const Key('camera_permission_denied')),
          findsOneWidget,
        );
        expect(find.text('ไม่ได้รับสิทธิ์ใช้กล้อง'), findsOneWidget);
        // Distinct from the no-camera screen.
        expect(find.text('ไม่พบกล้อง'), findsNothing);
        // Gallery still available; no shutter.
        expect(find.byIcon(Icons.photo_library), findsOneWidget);
        expect(find.byKey(const Key('camera_shutter')), findsNothing);
      },
    );

    testWidgets('while initializing -> shows a spinner', (tester) async {
      // An initializer that never completes keeps us in the initializing state.
      await tester.pumpWidget(
        MaterialApp(
          home: CameraScreen(
            initializer: () => Completer<CameraSetupResult>().future,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('ไม่พบกล้อง'), findsNothing);
    });
  });
}
