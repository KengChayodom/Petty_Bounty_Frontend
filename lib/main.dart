import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/routing/app_router.dart';

void main() {
  runApp(
  
    const ProviderScope(
      child: PettyBountyApp(),
    ),
  );
}

class PettyBountyApp extends ConsumerWidget {
  const PettyBountyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
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