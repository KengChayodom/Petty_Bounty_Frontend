import 'package:flutter/material.dart';

/// The four visual stages of a search, in order. This is a UI abstraction over
/// the backend `pet_status` / sighting activity — not a 1:1 enum mirror:
///   lost    -> report just filed (pet_status "Searching")
///   pending -> at least one sighting is awaiting verification
///   spotted -> a sighting was verified / the pet was seen for real
///   rescue  -> the pet was caught / the report is resolved ("Found")
enum TrackerStage { lost, pending, spotted, rescue }

/// Horizontal 4-step progress indicator (LOST → PENDING → SPOTTED → RESCUE).
/// Circles and connectors up to and including [current] are filled orange;
/// everything after is greyed out.
class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.current});

  final TrackerStage current;

  static const _orange = Color(0xFFF57C3A);
  static const _grey = Color(0xFFBDBDBD);

  static const _stages = <_StageSpec>[
    _StageSpec(TrackerStage.lost, 'LOST', Icons.bolt_rounded),
    _StageSpec(TrackerStage.pending, 'PENDING', Icons.hourglass_top_rounded),
    _StageSpec(TrackerStage.spotted, 'SPOTTED', Icons.visibility_rounded),
    _StageSpec(
        TrackerStage.rescue, 'RESCUE', Icons.volunteer_activism_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = current.index;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _stages.length; i++) ...[
          _buildNode(_stages[i], reached: i <= currentIndex),
          if (i < _stages.length - 1)
            Expanded(
              child: Padding(
                // Nudge the connector up to line through the circles' centers.
                padding: const EdgeInsets.only(top: 21),
                child: Container(
                  height: 3,
                  color: i < currentIndex ? _orange : _grey,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildNode(_StageSpec spec, {required bool reached}) {
    final color = reached ? _orange : _grey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(spec.icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          spec.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: reached ? Colors.black87 : _grey,
          ),
        ),
      ],
    );
  }
}

class _StageSpec {
  final TrackerStage stage;
  final String label;
  final IconData icon;
  const _StageSpec(this.stage, this.label, this.icon);
}
