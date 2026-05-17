import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../domain/sighting_providers.dart';
import '../../missions/data/mission_repository.dart';

class MatchingResultsScreen extends ConsumerWidget {
  const MatchingResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sightingState = ref.watch(sightingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Results'),
        backgroundColor: const Color(0xFFED7645),
        foregroundColor: Colors.white,
      ),
      body: sightingState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding matches...'),
                ],
              ),
            )
          : sightingState.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${sightingState.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Go Home'),
                        ),
                      ],
                    ),
                  ),
                )
              : sightingState.matches.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No matching pets found nearby',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your sighting has been recorded. If a matching pet is reported later, you will be notified.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => context.go('/'),
                              child: const Text('Go Home'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Header with match count
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: Colors.orange.shade50,
                          child: Column(
                            children: [
                              Text(
                                '${sightingState.matches.length} Potential Match${sightingState.matches.length == 1 ? '' : 'es'} Found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFED7645),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Review the matches below and accept a mission to help find the missing pet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Matches list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sightingState.matches.length,
                            itemBuilder: (context, index) {
                              final match = sightingState.matches[index];
                              return _MatchCard(
                                match: match,
                                sightingId: sightingState.sighting?.id ?? '',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final dynamic match;
  final String sightingId;

  const _MatchCard({
    required this.match,
    required this.sightingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarity = (match.similarity * 100).toStringAsFixed(0);
    final distance = match.distanceMeters < 1000
        ? '${match.distanceMeters.toStringAsFixed(0)}m'
        : '${(match.distanceMeters / 1000).toStringAsFixed(1)}km';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet image with similarity badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: match.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.pets, size: 64),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$similarity%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Pet details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.petName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(match.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        match.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildChip(Icons.pets, match.species),
                    const SizedBox(width: 8),
                    if (match.characteristics['color'] != null)
                      _buildChip(Icons.palette, match.characteristics['color']),
                  ],
                ),
                const SizedBox(height: 12),
                if (match.characteristics['size'] != null ||
                    match.characteristics['markings'] != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (match.characteristics['size'] != null)
                        Text(
                          match.characteristics['size'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (match.characteristics['markings'] != null)
                        Text(
                          '• ${match.characteristics['markings']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bounty',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '\$${match.bountyAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFED7645),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _acceptMission(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED7645),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Accept Mission'),
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

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Searching':
        return Colors.orange;
      case 'Spotted':
        return Colors.blue;
      case 'Found':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptMission(BuildContext context, WidgetRef ref) async {
    try {
      final missionRepo = ref.read(missionRepositoryProvider);
      await missionRepo.acceptMission(sightingId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission accepted! Good luck hunting!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept mission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
