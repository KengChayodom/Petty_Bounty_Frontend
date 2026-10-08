import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';

/// Switches the profile between the hunter view and the owner view. One
/// account plays both roles, so this is a view switch, not a mode.
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInk.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: kInk.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _segment('As hunter', 0)),
          const SizedBox(width: 6),
          Expanded(child: _segment('As owner', 1)),
        ],
      ),
    );
  }

  Widget _segment(String label, int index) {
    final selected = selectedTab == index;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? kBrandDeep : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => onTabSelected(index),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : kInk.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
