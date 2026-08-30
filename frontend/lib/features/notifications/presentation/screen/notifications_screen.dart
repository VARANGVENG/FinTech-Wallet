import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/fraud/presentation/screen/fraud_alert_screen.dart';
import 'package:fintech_wallet/features/notifications/data/model/app_notification.dart';
import 'package:fintech_wallet/features/notifications/presentation/provider/notifications_provider.dart';
import 'package:fintech_wallet/features/notifications/presentation/widget/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `ConsumerStatefulWidget`, not `ConsumerWidget` — needs `initState` for
/// two things a stateless widget can't do: owning the `TabController`
/// (requires a `vsync`, tied to this widget's lifecycle) and the one-time
/// `markAllAsRead()` call, same "load/act once" convention every other
/// screen's `initState` already follows.
class NotificationsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const NotificationsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllAsRead();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final alerts = notifications
        .where((n) => n.category == NotificationCategory.alert)
        .toList();
    final transactions = notifications
        .where((n) => n.category == NotificationCategory.transaction)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentBlue,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Alerts'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationList(notifications: alerts),
          _NotificationList(notifications: transactions),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'Nothing here yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.cardBorder),
      itemBuilder: (context, index) {
        final notification = notifications[index];

        VoidCallback? onTap;
        if (notification.isFraudAlert) {
          onTap = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FraudAlertScreen()),
          );
        } 
        return NotificationTile(notification: notification, onTap: onTap);
      },
    );
  }
}
