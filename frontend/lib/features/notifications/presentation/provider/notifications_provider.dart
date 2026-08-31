import 'package:fintech_wallet/features/transactions/presentation/providers/transaction_history_provider.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
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
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
      return NotificationsNotifier();
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});
final transactionNotificationsProvider =
    Provider<AsyncValue<List<AppNotification>>>((ref) {
      final currencyCode =
          ref.watch(walletProvider).valueOrNull?.currency ?? 'USD';
      return ref
          .watch(transactionHistoryProvider)
          .whenData(
            (txns) => txns
                .map(
                  (t) => AppNotification.fromTransaction(
                    t,
                    currencyCode: currencyCode,
                  ),
                )
                .toList(),
          );
    });
