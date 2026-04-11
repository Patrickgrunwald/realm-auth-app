import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/supabase_service.dart';

class EANotifier extends StateNotifier<EAModerationState> {
  EANotifier() : super(const EAModerationState());

  Future<bool> reportPost(String postId, {String? reason}) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return false;

    // TODO: Supabase upsert
    // await SupabaseService.client.from('ea_reports').upsert({
    //   'post_id': postId,
    //   'reporter_id': userId,
    //   'reason': reason,
    // });

    print('[EA] Report: postId=$postId reason=$reason');
    return true;
  }
}

class EAModerationState {
  final bool isLoading;
  final String? error;

  const EAModerationState({
    this.isLoading = false,
    this.error,
  });
}

final eaControllerProvider = StateNotifierProvider<EANotifier, EAModerationState>((ref) {
  return EANotifier();
});
