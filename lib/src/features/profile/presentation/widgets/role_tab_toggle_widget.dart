import 'package:flutter/material.dart';

/// Role selector tab bar (Hunter 🤠 vs Pet Owner 🐾).
class RoleTabToggleWidget extends StatelessWidget {
  const RoleTabToggleWidget({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final int selectedTab; // 0 = Hunter, 1 = Pet Owner
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          // Hunter Tab Button
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(0),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: selectedTab == 0
                      ? const Color(0xFFD4E2FF)
                      : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedTab == 0
                          ? const Color(0xFF0022FF)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.sports_rounded,
                  size: 28,
                  color: selectedTab == 0
                      ? const Color(0xFF0022FF)
                      : Colors.grey[400],
                ),
              ),
            ),
          ),

          // Pet Owner Tab Button
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(1),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: selectedTab == 1
                      ? const Color(0xFFFFE5D9)
                      : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedTab == 1
                          ? const Color(0xFFFF7A00)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  size: 26,
                  color: selectedTab == 1
                      ? const Color(0xFFFF7A00)
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
