import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/lost_pet_post_form_provider.dart';

/// "Last seen time" tile — opens a date then time picker and stores the
/// combined DateTime.
class LastSeenTimeWidget extends ConsumerWidget {
  const LastSeenTimeWidget({super.key});

  Future<void> _selectDateTime(BuildContext context, WidgetRef ref) async {
    final currentLastSeenTime =
        ref.read(lostPetPostFormProvider).lastSeenTime;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentLastSeenTime,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentLastSeenTime),
    );
    if (pickedTime == null || !context.mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    ref.read(lostPetPostFormProvider.notifier).updateLastSeenTime(combined);
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSeenTime = ref.watch(
      lostPetPostFormProvider.select((state) => state.lastSeenTime),
    );

    return GestureDetector(
      onTap: () => _selectDateTime(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.blue, size: 22),
            const SizedBox(width: 12),
            Text(
              'Lost at ${_formatDateTime(lastSeenTime)}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
