import 'package:flutter/material.dart';

/// Reusable stat card widget for Hunter & Pet Owner career metrics.
class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.numberText,
    required this.numberColor,
    required this.label,
    required this.labelColor,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String numberText;
  final Color numberColor;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 6),
          Text(
            numberText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: numberColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
