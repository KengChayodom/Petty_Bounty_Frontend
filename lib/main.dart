import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'src/core/app_config.dart';
import 'src/core/notifications/fcm_service.dart';
import 'src/core/ui/skeleton/skeleton.dart';
import 'src/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase handles Auth (Feature #6), Storage and Realtime directly from the
  // client. It persists and silently refreshes the session across app restarts.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Firebase / FCM push (SRS-FR-12). initializeApp + the background handler do
  // NOT prompt the user, so they're safe to run at launch. The notification
  // PERMISSION prompt is deliberately NOT triggered here — HomeScreen fires it
  // after the location permission flow settles, so the two native permission
  // dialogs never race (which made the OS drop the location one). See
  // FcmService + HomeScreen._initPushAfterLocation.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: PettyBountyApp()));
}

class PettyBountyApp extends ConsumerStatefulWidget {
  const PettyBountyApp({super.key});

  @override
  ConsumerState<PettyBountyApp> createState() => _PettyBountyAppState();
}

class _PettyBountyAppState extends ConsumerState<PettyBountyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // App startup: a user whose session was restored from disk is already
    // signed in here and may never pass through the login screen again, so
    // this is the only place their token gets refreshed on a normal launch.
    // `syncToken` no-ops while signed out and never prompts for permission,
    // so it cannot race the location dialog (the permission prompt itself
    // still lives in HomeScreen, after the location flow — see FcmService).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.instance.syncToken();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // FCM can rotate a token while the app is backgrounded, and onTokenRefresh
    // only fires for a live isolate. Re-syncing on resume closes that window;
    // an unchanged token costs nothing (syncToken memoises what it registered).
    if (state == AppLifecycleState.resumed) {
      FcmService.instance.syncToken();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Petty Bounty',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // Skeleton loading is the app's only pending-state affordance (there
        // are no spinners / progress indicators anywhere). Registering the
        // config here means a bare `Skeletonizer(child: ...)` in any feature
        // inherits the shared shimmer instead of restating it.
        extensions: const <ThemeExtension<dynamic>>[AppSkeletons.config],
      ),
      routerConfig: goRouter,
      builder: (context, child) {
        return SafeArea(
          // You can disable SafeArea on specific edges if needed (e.g., for full-screen maps later)
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: child!,
        );
      },
    );
  }
}
