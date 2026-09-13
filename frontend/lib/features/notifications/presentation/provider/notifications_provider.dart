import 'package:fintech_wallet/features/transactions/presentation/providers/transaction_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/mock_alert_notifications.dart';
import '../../data/model/app_notification.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(_buildInitial());

  static List<AppNotification> _buildInitial() {
    return [...mockAlertNotifications];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  /// Inserts a notification built from a live FCM push so it shows up in
  /// the Alerts tab immediately - only needed for the foreground case,
  /// since the app isn't running to update this state otherwise.
  void addPushNotification(AppNotification notification) {
    state = [notification, ...state];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
      return NotificationsNotifier();
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});
/// Parameterized by currency (one wallet's history at a time, same model
/// WalletScreen already uses) rather than always the default wallet -
/// Transaction itself carries no currency of its own, so whichever wallet's
/// history this reads is also what labels every row.
final transactionNotificationsProvider = Provider.family<
    AsyncValue<List<AppNotification>>, String>((ref, currency) {
  final state = ref.watch(walletTransactionsProvider(currency));

  if (state.isLoading) return const AsyncValue.loading();
  if (state.error != null) {
    return AsyncValue.error(
      state.error!,
      state.stackTrace ?? StackTrace.current,
    );
  }

  return AsyncValue.data(
    state.transactions
        .map(
          (t) => AppNotification.fromTransaction(t, currencyCode: currency),
        )
        .toList(),
  );
});
