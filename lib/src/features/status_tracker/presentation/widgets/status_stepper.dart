import 'package:flutter/material.dart';

import '../../../../core/theme/app_glass.dart';

/// The four visual stages of a search, in order. This is a UI abstraction over
/// the backend's derived `post_status` — not a mirror of the `pet_status`
/// storage column, which uses different words for different things:
///   lost    -> the base step; a report exists
///   pending -> no sighting has come in yet (post_status "Pending"/"Expired")
///   spotted -> at least one sighting counts for this pet ("Spotted")
///   rescue  -> the search has ended ("Rescued" — i.e. Found or Resolved)
///
/// The mapping lives in `StatusTrackerScreen._deriveStage`; the rule behind
/// those words lives in `app/services/pet_logic.py`.
enum TrackerStage { lost, pending, spotted, rescue }

/// A four-segment progress bar (Reported, Waiting, Seen, Home) with the
/// stage names under it. Segments up to and including [current] are filled.
class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.current});

  final TrackerStage current;

  static const _labels = ['Reported', 'Waiting', 'Seen', 'Home'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = current.index;
    return Semantics(
      label: 'Search progress: ${_labels[currentIndex]}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < _labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= currentIndex
                          ? kBrandDeep
                          : kInk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: Text(
                    _labels[i],
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == _labels.length - 1
                            ? TextAlign.right
                            : TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                      color: i == currentIndex
                          ? kInk
                          : kInk.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
