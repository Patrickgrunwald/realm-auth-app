import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/supabase_service.dart';

class EaState {
  final bool isLoading;
  final String? error;
  final bool reportSent;

  const EaState({
    this.isLoading = false,
    this.error,
    this.reportSent = false,
  });

  EaState copyWith({
    bool? isLoading,
    String? error,
    bool? reportSent,
  }) {
    return EaState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      reportSent: reportSent ?? this.reportSent,
    );
  }
}

class EaNotifier extends StateNotifier<EaState> {
  EaNotifier() : super(const EaState());

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null, reportSent: false);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;

      await SupabaseService.client
          .from(AppConstants.eaReportsTable)
          .insert({
            if (userId != null) 'reporter_id': userId,
            'post_id': postId,
            'reason': reason,
            'description': description,
          });

      state = state.copyWith(isLoading: false, reportSent: true);
    } catch (e) {
      debugPrint('[EaController] reportPost error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const EaState();
  }
}

final eaControllerProvider =
    StateNotifierProvider<EaNotifier, EaState>((ref) {
  return EaNotifier();
});