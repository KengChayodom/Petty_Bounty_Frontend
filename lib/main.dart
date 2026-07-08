import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'src/core/app_config.dart';
import 'src/core/notifications/fcm_service.dart';
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

class PettyBountyApp extends ConsumerWidget {
  const PettyBountyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Petty Bounty',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
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
