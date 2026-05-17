import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/mission_model.dart';
import '../data/mission_repository.dart';

/// State for active missions
class MissionsState {
  final bool isLoading;
  final String? errorMessage;
  final List<MissionModel> activeMissions;
  final List<MissionModel> missionHistory;

  const MissionsState({
    this.isLoading = false,
    this.errorMessage,
    this.activeMissions = const [],
    this.missionHistory = const [],
  });

  MissionsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<MissionModel>? activeMissions,
    List<MissionModel>? missionHistory,
  }) {
    return MissionsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeMissions: activeMissions ?? this.activeMissions,
      missionHistory: missionHistory ?? this.missionHistory,
    );
  }
}

/// StateNotifier for managing missions
class MissionsNotifier extends StateNotifier<MissionsState> {
  final MissionRepository _repository;

  MissionsNotifier(this._repository) : super(const MissionsState());

  /// Accept a mission
  Future<MissionModel> acceptMission(String sightingId) async {
    try {
      final mission = await _repository.acceptMission(sightingId);
      // Refresh active missions after accepting
      await loadActiveMissions();
      return mission;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Load active missions
  Future<void> loadActiveMissions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final missions = await _repository.getActiveMissions();
      state = state.copyWith(
        activeMissions: missions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load mission history
  Future<void> loadMissionHistory({int limit = 20}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final history = await _repository.getMissionHistory(limit: limit);
      state = state.copyWith(
        missionHistory: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update mission status
  Future<void> updateMissionStatus({
    required String sightingId,
    required String status,
    String? notes,
  }) async {
    try {
      await _repository.updateMissionStatus(
        sightingId: sightingId,
        status: status,
        notes: notes,
      );
      // Refresh active missions after updating
      await loadActiveMissions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }
}

/// Provider for MissionsNotifier
final missionsNotifierProvider =
    StateNotifierProvider<MissionsNotifier, MissionsState>((ref) {
  final repository = ref.watch(missionRepositoryProvider);
  return MissionsNotifier(repository);
});
