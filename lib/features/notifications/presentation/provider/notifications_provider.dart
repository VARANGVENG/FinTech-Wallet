import 'package:fintech_wallet/core/mock/mock_transaction_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/mock_alert_notifications.dart';
import '../../data/model/app_notification.dart';

/// Combines the mock alert list with transaction history reformatted as
/// notifications. Held as plain in-memory Riverpod state — no persistence
/// was asked for here, unlike Settings' toggles, so this resets each app
/// session, same as `TopUpState`/`TransferState` do.
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(_buildInitial());

  static List<AppNotification> _buildInitial() {
    final transactionNotifications = transactionHistory.map((t) {
      return AppNotification(
        id: 'txn_${t.id}',
        category: NotificationCategory.transaction,
        title: t.isIncome ? 'Money Received' : 'Transaction Completed',
        message: t.isIncome
            ? 'You received a payment from ${t.title}.'
            : 'Your transaction at ${t.title} was completed.',
        timestamp: t.transactionDate,
        icon: t.icon,
        transaction: t,
      );
    }).toList();

    return [...mockAlertNotifications, ...transactionNotifications];
  }

  /// Called once when `NotificationsScreen` opens — clears the unread
  /// badge, same "viewing the list marks it read" behavior most apps use.
  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
      return NotificationsNotifier();
    });

/// A separate derived [Provider], not a getter on the notifier — this
/// matters. Reading `ref.watch(notificationsProvider.notifier).unreadCount`
/// from a getter would NOT rebuild widgets when the list changes, since
/// watching `.notifier` only reacts to the notifier *instance* changing,
/// never to its internal state. This provider watches the actual state
/// (`ref.watch(notificationsProvider)`), so it recomputes and notifies
/// correctly whenever a notification is marked read.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});
