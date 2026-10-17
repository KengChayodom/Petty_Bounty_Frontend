// Widget tests for CameraScreen: bringing the camera up, the shutter, and the
// gallery button.
//
// No real camera or photo library is touched. CameraScreen exposes an
// [initializer] seam that returns a CameraSetupResult and a [previewBuilder]
// seam so the "ready" UI renders without a platform-backed controller. The
// shutter cases use a CameraController subclass that reports itself as
// initialized and scripts takePicture. The gallery cases answer the
// image_picker method channel (the package does not export its platform
// interface, so the channel is the boundary reachable without a new
// dependency). The upload that starts on capture goes to a fake
// SightingRepository through ProviderScope, and navigation runs on a test
// GoRouter whose 'verification' route records the arguments it received.

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petty_bounty/src/features/sightings/data/sighting_repository.dart';
import 'package:petty_bounty/src/features/sightings/domain/pending_upload.dart';
import 'package:petty_bounty/src/features/sightings/domain/sighting_providers.dart';
import 'package:petty_bounty/src/features/sightings/presentation/camera_screen.dart';
import 'package:petty_bounty/src/features/sightings/presentation/widgets/camera_skeletons.dart';

const _camera = CameraDescription(
  name: 'fake',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 0,
);

// A controller that is never initialize()'d. Its dispose() does not call the
// platform, so it is safe to construct and tear down in a widget test.
CameraController _uninitializedController() =>
    CameraController(_camera, ResolutionPreset.low, enableAudio: false);

/// Reports itself as initialized (unless [initialized] is false) and answers
/// takePicture from [onTake], without initialize() ever reaching the platform.
class _ReadyController extends CameraController {
  _ReadyController(this.onTake, {bool initialized = true})
    : super(_camera, ResolutionPreset.low, enableAudio: false) {
    value = value.copyWith(isInitialized: initialized);
  }

  final Future<XFile> Function() onTake;
  int takeCalls = 0;

  @override
  Future<XFile> takePicture() {
    takeCalls++;
    return onTake();
  }
}

class _FakeSightingRepo implements SightingRepository {
  final List<String> uploaded = [];

  @override
  Future<String> uploadImage(String filePath) async {
    uploaded.add(filePath);
    return 'https://storage/$filePath';
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName} not used in this test');
}

/// Pumps CameraScreen at '/' of a test router. The 'verification' route stores
/// the arguments it is opened with in [pushed].
class _Harness {
  final repo = _FakeSightingRepo();
  Map<String, dynamic>? pushed;

  Future<void> pump(
    WidgetTester tester, {
    required CameraInitializer initializer,
    CameraPreviewBuilder? previewBuilder,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => CameraScreen(
            initializer: initializer,
            previewBuilder: previewBuilder ?? (_) => const SizedBox.expand(),
          ),
        ),
        GoRoute(
          path: '/verification',
          name: 'verification',
          builder: (_, state) {
            pushed = state.extra as Map<String, dynamic>?;
            return const Scaffold(body: Text('verification screen'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sightingRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }
}

const _pickerChannel = MethodChannel('plugins.flutter.io/image_picker');

/// Answers the photo library request with [answer].
void _answerPicker(
  WidgetTester tester,
  Future<Object?> Function(MethodCall call) answer,
) {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_pickerChannel, answer);
  addTearDown(() => messenger.setMockMethodCallHandler(_pickerChannel, null));
}

void main() {
  group('CameraScreen._runInitializer', () {
    testWidgets('TC-01 while initializing -> skeleton, never a spinner', (
      tester,
    ) async {
      // An initializer that never completes keeps the screen in this state.
      await tester.pumpWidget(
        MaterialApp(
          home: CameraScreen(
            initializer: () => Completer<CameraSetupResult>().future,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CameraInitializingSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('camera_ready')), findsNothing);
      expect(find.text('ไม่พบกล้อง'), findsNothing);
    });

    testWidgets('TC-02 has camera -> preview, shutter and gallery button', (
      tester,
    ) async {
      final controller = _uninitializedController();
      addTearDown(controller.dispose);

      await _Harness().pump(
        tester,
        initializer: () async =>
            CameraSetupResult(CameraSetupStatus.ready, controller: controller),
      );

      expect(find.byKey(const Key('camera_ready')), findsOneWidget);
      expect(find.byKey(const Key('camera_shutter')), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.text('ไม่พบกล้อง'), findsNothing);
      expect(find.text('ไม่ได้รับสิทธิ์ใช้กล้อง'), findsNothing);
    });

    testWidgets('TC-03 no camera -> "ไม่พบกล้อง" with gallery, no shutter', (
      tester,
    ) async {
      await _Harness().pump(
        tester,
        initializer: () async =>
            const CameraSetupResult(CameraSetupStatus.unavailable),
      );

      expect(find.byKey(const Key('camera_no_camera')), findsOneWidget);
      expect(find.text('ไม่พบกล้อง'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byKey(const Key('camera_shutter')), findsNothing);
      expect(find.byKey(const Key('camera_ready')), findsNothing);
    });

    testWidgets(
      'TC-04 permission denied -> "ไม่ได้รับสิทธิ์ใช้กล้อง" with gallery',
      (tester) async {
        await _Harness().pump(
          tester,
          initializer: () async =>
              const CameraSetupResult(CameraSetupStatus.permissionDenied),
        );

        expect(
          find.byKey(const Key('camera_permission_denied')),
          findsOneWidget,
        );
        expect(find.text('ไม่ได้รับสิทธิ์ใช้กล้อง'), findsOneWidget);
        expect(find.text('ไม่พบกล้อง'), findsNothing);
        expect(find.byIcon(Icons.photo_library), findsOneWidget);
        expect(find.byKey(const Key('camera_shutter')), findsNothing);
      },
    );

    testWidgets('TC-05 screen closed before the camera answers -> no error', (
      tester,
    ) async {
      final pending = Completer<CameraSetupResult>();
      await tester.pumpWidget(
        MaterialApp(home: CameraScreen(initializer: () => pending.future)),
      );
      await tester.pumpWidget(const SizedBox());

      pending.complete(const CameraSetupResult(CameraSetupStatus.unavailable));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('CameraScreen._takePicture', () {
    testWidgets('TC-01 controller not initialized -> no capture, stays', (
      tester,
    ) async {
      final h = _Harness();
      final controller = _ReadyController(
        () async => XFile('/tmp/shot.jpg'),
        initialized: false,
      );
      addTearDown(controller.dispose);
      await h.pump(
        tester,
        initializer: () async =>
            CameraSetupResult(CameraSetupStatus.ready, controller: controller),
      );

      await tester.tap(find.byKey(const Key('camera_shutter')));
      await tester.pumpAndSettle();

      expect(controller.takeCalls, 0);
      expect(find.byKey(const Key('camera_ready')), findsOneWidget);
      expect(h.pushed, isNull);
      expect(h.repo.uploaded, isEmpty);
    });

    testWidgets('TC-02 photo taken -> verification opened, upload started', (
      tester,
    ) async {
      final h = _Harness();
      final controller = _ReadyController(() async => XFile('/tmp/shot.jpg'));
      addTearDown(controller.dispose);
      await h.pump(
        tester,
        initializer: () async =>
            CameraSetupResult(CameraSetupStatus.ready, controller: controller),
      );

      await tester.tap(find.byKey(const Key('camera_shutter')));
      await tester.pumpAndSettle();

      expect(controller.takeCalls, 1);
      expect(find.text('verification screen'), findsOneWidget);
      expect(h.pushed!['imagePath'], '/tmp/shot.jpg');
      expect(h.pushed!['targetPetId'], isNull);
      expect(h.pushed!['pendingUpload'], isA<PendingUpload>());
      expect(h.repo.uploaded, ['/tmp/shot.jpg']);
    });

    testWidgets('TC-03 capture fails -> stays on camera, shutter back', (
      tester,
    ) async {
      final h = _Harness();
      final controller = _ReadyController(
        () async => throw CameraException('captureFailed', 'boom'),
      );
      addTearDown(controller.dispose);
      await h.pump(
        tester,
        initializer: () async =>
            CameraSetupResult(CameraSetupStatus.ready, controller: controller),
      );

      await tester.tap(find.byKey(const Key('camera_shutter')));
      await tester.pumpAndSettle();

      expect(controller.takeCalls, 1);
      expect(h.pushed, isNull);
      expect(h.repo.uploaded, isEmpty);
      expect(find.byKey(const Key('camera_shutter')), findsOneWidget);
      expect(find.byType(CameraBusyBar), findsNothing);
    });
  });

  group('CameraScreen._pickFromGallery', () {
    Future<_Harness> pumpNoCamera(WidgetTester tester) async {
      final h = _Harness();
      await h.pump(
        tester,
        initializer: () async =>
            const CameraSetupResult(CameraSetupStatus.unavailable),
      );
      return h;
    }

    testWidgets('TC-01 photo chosen -> verification opened, upload started', (
      tester,
    ) async {
      _answerPicker(tester, (_) async => '/tmp/gallery.jpg');
      final h = await pumpNoCamera(tester);

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(find.text('verification screen'), findsOneWidget);
      expect(h.pushed!['imagePath'], '/tmp/gallery.jpg');
      expect(h.pushed!['pendingUpload'], isA<PendingUpload>());
      expect(h.repo.uploaded, ['/tmp/gallery.jpg']);
    });

    testWidgets('TC-02 picker closed without a photo -> stays, button back', (
      tester,
    ) async {
      _answerPicker(tester, (_) async => null);
      final h = await pumpNoCamera(tester);

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(h.pushed, isNull);
      expect(h.repo.uploaded, isEmpty);
      expect(find.byKey(const Key('camera_no_camera')), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('TC-03 photo library access denied -> stays, button back', (
      tester,
    ) async {
      _answerPicker(
        tester,
        (_) async => throw PlatformException(code: 'photo_access_denied'),
      );
      final h = await pumpNoCamera(tester);

      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(h.pushed, isNull);
      expect(h.repo.uploaded, isEmpty);
      expect(find.byKey(const Key('camera_no_camera')), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
