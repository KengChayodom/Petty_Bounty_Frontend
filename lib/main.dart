import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/routing/app_router.dart';

void main() {
  runApp(
    // ProviderScope is strictly required to use Riverpod in the app
    const ProviderScope(
      child: PettyBountyApp(),
    ),
  );
}

class PettyBountyApp extends ConsumerWidget {
  const PettyBountyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the GoRouter configuration from our provider
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Petty Bounty',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: goRouter, // Inject GoRouter here
    );
  }
}