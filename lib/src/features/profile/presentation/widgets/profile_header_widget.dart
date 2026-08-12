import 'package:flutter/material.dart';

/// User Avatar + Display Name + Contact Details Header card.
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.displayName,
    required this.phone,
    required this.email,
    this.photoUrl,
    required this.onEditPressed,
  });

  final String displayName;
  final String phone;
  final String email;
  final String? photoUrl;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.grey[200],
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Icon(Icons.person, size: 36, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onEditPressed,
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tel. ${phone.isNotEmpty ? phone : '0912131209'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Email ${email.isNotEmpty ? email : 'chayodom@cmu.ac.th'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
