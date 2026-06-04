import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';

/// Read-only account page (Feature #6). Profile editing is not yet supported;
/// this screen just shows the signed-in user's basic info and hosts logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        (user?.userMetadata?['display_name'] as String?)?.trim();
    final email = user?.email ?? '—';
    final phone = (user?.userMetadata?['phone'] as String?)?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF335BCC),
                  child: Image.asset(
                    'assets/user.png',
                    width: 44,
                    height: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName?.isNotEmpty == true
                      ? displayName!
                      : 'Petty Bounty user',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: email),
          if (phone?.isNotEmpty == true)
            _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: phone!),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Profile editing is coming soon.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text(
              'Log out',
              style: TextStyle(color: Colors.redAccent),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF335BCC)),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
    );
  }
}
