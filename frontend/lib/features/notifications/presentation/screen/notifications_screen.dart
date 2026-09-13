import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/fraud/presentation/screen/fraud_alert_screen.dart';
import 'package:fintech_wallet/features/notifications/data/model/app_notification.dart';
import 'package:fintech_wallet/features/notifications/presentation/provider/notifications_provider.dart';
import 'package:fintech_wallet/features/notifications/presentation/widget/notification_tile.dart';
import 'package:fintech_wallet/features/wallet/domain/entities/wallet.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `ConsumerStatefulWidget`, not `ConsumerWidget` — needs `initState` for
/// two things a stateless widget can't do: owning the `TabController`
/// (requires a `vsync`, tied to this widget's lifecycle) and reacting to
/// which tab is actually active to decide when `markAllAsRead()` runs.
class NotificationsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const NotificationsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  static const _alertsTabIndex = 0;

  late final TabController _tabController;
  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_markAlertsReadIfAlertsTabActive);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAlertsReadIfAlertsTabActive();
    });
  }

  /// Alerts should only be marked read once the user is actually looking at
  /// the Alerts tab — not merely because this screen mounted. Without this,
  /// opening straight to the Transactions tab (e.g. the "See all" link on
  /// the dashboard, which passes `initialTabIndex: 1`) would silently clear
  /// the Alerts unread badge for alerts the user never saw.
  /// `indexIsChanging` is true only mid-animation when a tab is tapped
  /// (not while the user is dragging the page view), so this fires once the
  /// tab actually settles rather than on every intermediate tick.
  void _markAlertsReadIfAlertsTabActive() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == _alertsTabIndex) {
      ref.read(notificationsProvider.notifier).markAllAsRead();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_markAlertsReadIfAlertsTabActive);
    _tabController.dispose();
    super.dispose();
  }

  /// Same resolution WalletScreen uses: whatever the user last picked here,
  /// else the default wallet, else just the first one - so this tab shows
  /// something sensible before the user has ever touched the picker.
  Wallet _resolveSelected(List<Wallet> wallets) {
    if (_selectedCurrency != null) {
      for (final wallet in wallets) {
        if (wallet.currency == _selectedCurrency) return wallet;
      }
    }
    for (final wallet in wallets) {
      if (wallet.isDefault) return wallet;
    }
    return wallets.first;
  }

  Future<void> _handleCurrencyTap(
    List<Wallet> wallets,
    String currentCurrency,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final wallet in wallets)
                ListTile(
                  title: Text(
                    wallet.currency,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: wallet.currency == currentCurrency
                      ? const Icon(Icons.check, color: AppColors.accentBlue)
                      : null,
                  onTap: () => Navigator.pop(context, wallet.currency),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => _selectedCurrency = selected);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final alerts = notifications
        .where((n) => n.category == NotificationCategory.alert)
        .toList();
    final walletsAsync = ref.watch(walletsProvider);

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
          walletsAsync.when(
            data: (wallets) => _TransactionsTab(
              wallets: wallets,
              resolveSelected: _resolveSelected,
              onCurrencyTap: _handleCurrencyTap,
            ),
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stackTrace) => Center(
              child: Text(
                "Couldn't load transactions",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Transactions tab's own content: a currency picker (only shown when
/// there's more than one wallet to choose from - same threshold WalletScreen
/// uses) above the list for whichever currency is currently selected.
class _TransactionsTab extends ConsumerWidget {
  final List<Wallet> wallets;
  final Wallet Function(List<Wallet> wallets) resolveSelected;
  final Future<void> Function(List<Wallet> wallets, String currentCurrency)
  onCurrencyTap;

  const _TransactionsTab({
    required this.wallets,
    required this.resolveSelected,
    required this.onCurrencyTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (wallets.isEmpty) {
      return const Center(
        child: Text(
          'No wallet found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final selected = resolveSelected(wallets);
    final transactionsAsync = ref.watch(
      transactionNotificationsProvider(selected.currency),
    );

    return Column(
      children: [
        if (wallets.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => onCurrencyTap(wallets, selected.currency),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Text(
                        selected.currency,
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.surface,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) =>
                _NotificationList(notifications: transactions),
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stackTrace) => Center(
              child: Text(
                "Couldn't load transactions",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
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
