import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../domain/mission_providers.dart';
import '../data/models/mission_model.dart';

class ActiveMissionsScreen extends ConsumerStatefulWidget {
  const ActiveMissionsScreen({super.key});

  @override
  ConsumerState<ActiveMissionsScreen> createState() =>
      _ActiveMissionsScreenState();
}

class _ActiveMissionsScreenState extends ConsumerState<ActiveMissionsScreen> {
  @override
  void initState() {
    super.initState();
    // Load missions when screen opens
    Future.microtask(() {
      ref.read(missionsNotifierProvider.notifier).loadActiveMissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final missionsState = ref.watch(missionsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Missions'),
        backgroundColor: const Color(0xFFED7645),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(missionsNotifierProvider.notifier).loadActiveMissions();
            },
          ),
        ],
      ),
      body: missionsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : missionsState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${missionsState.errorMessage}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(missionsNotifierProvider.notifier)
                              .loadActiveMissions();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : missionsState.activeMissions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No active missions',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Accept a mission from a match to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () {
                        return ref
                            .read(missionsNotifierProvider.notifier)
                            .loadActiveMissions();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: missionsState.activeMissions.length,
                        itemBuilder: (context, index) {
                          final mission = missionsState.activeMissions[index];
                          return _MissionCard(mission: mission);
                        },
                      ),
                    ),
    );
  }
}

class _MissionCard extends ConsumerWidget {
  final MissionModel mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: mission.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 64),
              ),
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(mission.sightingStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        mission.sightingStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(mission.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.pets, size: 18, color: Color(0xFFED7645)),
                    const SizedBox(width: 8),
                    Text(
                      mission.detectedSpecies,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (mission.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    mission.notes!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showCompleteDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Close Mission'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // View details or navigate to map
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED7645),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending_Analysis':
        return Colors.orange;
      case 'Notified_Owner':
        return Colors.blue;
      case 'Confirmed':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Mission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Did you find the pet?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Add notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(missionsNotifierProvider.notifier).updateMissionStatus(
                  sightingId: mission.id,
                  status: 'Closed',
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mission completed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to complete mission: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
