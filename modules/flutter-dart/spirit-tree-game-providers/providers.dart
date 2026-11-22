import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games_services/games_services.dart' as gservices
    show GamesServices;

import 'core/platform_utils.dart';
import 'models/game_state.dart';
import 'notifiers/game_notifier.dart';
import 'services/iap_manager.dart';
import 'services/leaderboard_service.dart';
import 'services/save_manager.dart';
import 'services/sound_manager.dart';

// --- Core Game Provider ---
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final notifier = GameNotifier(ref);
  ref.onDispose(() => notifier.cancelTimer());
  return notifier;
});

// --- UI State Providers ---
final levelUpMultiplierProvider = StateProvider<int>((ref) => 1);
final parallaxProvider = StateProvider<Offset>((ref) => Offset.zero);

// --- Collapsible Panel Providers ---
final spiritsPanelExpandedProvider = StateProvider<bool>((ref) => true);

// --- Service Providers ---
final soundManagerProvider = Provider<SoundManager>((ref) => SoundManager());
final iapManagerProvider = Provider<IAPManager>((ref) => IAPManager(ref));
final saveManagerProvider = Provider<SaveManager>((ref) => SaveManager(ref));
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) => LeaderboardService());

// --- Stream Providers ---
final sunSpiritCooldownStreamProvider =
    StreamProvider.autoDispose<Duration>((ref) {
  final cooldownEnd =
      ref.watch(gameProvider.select((s) => s.sunSpiritCooldown));
  if (cooldownEnd == null || DateTime.now().isAfter(cooldownEnd)) {
    return Stream.value(Duration.zero);
  }
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final remaining = cooldownEnd.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  });
});

final adBuffTimerProvider = StreamProvider.autoDispose<Duration>((ref) {
  final buffEndTime = ref.watch(gameProvider.select((s) => s.buffEndTime));
  if (buffEndTime == null || DateTime.now().isAfter(buffEndTime)) {
    return Stream.value(Duration.zero);
  }
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final remaining = buffEndTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  });
});

// --- Offline & Cloud Save Providers ---
class OfflineRewardInfo {
  final Duration duration;
  final double reward;
  OfflineRewardInfo({required this.duration, required this.reward});
}

final offlineRewardProvider = StateProvider<OfflineRewardInfo?>((ref) => null);

final isSignedInProvider = FutureProvider<bool>((ref) async {
  if (!PlatformUtils.supportsGamesServices) {
    return false;
  }
  try {
    return await gservices.GamesServices.isSignedIn;
  } catch (_) {
    return false;
  }
});
