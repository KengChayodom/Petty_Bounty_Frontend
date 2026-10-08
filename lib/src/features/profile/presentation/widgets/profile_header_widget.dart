import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';
import '../../../../core/ui/brand_widgets.dart';

/// The account's avatar, name and contact details, drawn in light text on the
/// profile screen's dark header band.
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.username,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.onEditPressed,
  });

  final String username;
  final String phone;
  final String email;
  final String? photoUrl;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final muted = kDaylight.withValues(alpha: 0.8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kDaylight.withValues(alpha: 0.7), width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFCDB6A2),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 32, color: kDaylight)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: displayStyle(size: 28, color: kDaylight),
                ),
                const SizedBox(height: 6),
                // The phone doubles as the PromptPay number a reward is paid
                // to, so the header says so: that is why it must be right.
                Text(
                  phone.isNotEmpty ? '$phone, used for PromptPay' : 'Add a phone number to receive rewards',
                  style: TextStyle(fontSize: 14, color: muted),
                ),
                if (email.isNotEmpty)
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit profile',
            onPressed: onEditPressed,
          ),
        ],
      ),
    );
  }
}
