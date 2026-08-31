import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/notifications/presentation/provider/notifications_provider.dart';
import 'package:fintech_wallet/features/notifications/presentation/screen/notifications_screen.dart';
import 'package:fintech_wallet/features/transactions/presentation/providers/transaction_history_provider.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fintech_wallet/shared/widgets/custom_transaction_history_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BalanceOverviewScaffold extends ConsumerWidget {
  final Widget? headerLeading;
  final String headerTitle;
  final double? headerTitleFontSize;
  final VoidCallback? onHeaderTap;
  final Widget balanceCard;
  final List<Widget> quickActions;
  final String sectionTitle;
  final String? walletCurrency;

  const BalanceOverviewScaffold({
    super.key,
    this.headerLeading,
    required this.headerTitle,
    this.headerTitleFontSize,
    this.onHeaderTap,
    required this.balanceCard,
    required this.quickActions,
    required this.sectionTitle,
    this.walletCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final currency = walletCurrency;
    final transactionsAsync = currency == null
        ? ref.watch(transactionHistoryProvider)
        : ref.watch(walletTransactionsProvider(currency));
    final currencyCode =
        ref.watch(walletProvider).valueOrNull?.currency ?? 'USD';
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.background),
      body: Container(
        width: double.infinity,
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onHeaderTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ?headerLeading,
                        const SizedBox(width: 10),
                        Text(
                          headerTitle,
                          style: TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w900,
                            fontSize: headerTitleFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(19, 230, 221, 221),
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          child: Icon(
                            Icons.notifications,
                            color: AppColors.surface,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              balanceCard,
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: quickActions,
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Text(
                    sectionTitle,
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(initialTabIndex: 1),
                      ),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 7, 143, 255),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2338).withValues(alpha: 0.26),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: AppColors.surface.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 3,
                          indent: 30,
                          endIndent: 30,
                          color: AppColors.cardBorder,
                        ),
                        itemBuilder: (context, index) =>
                            CustomTransactionHistoryItem(
                              transaction: transactions[index],
                              currencyCode: currencyCode,
                            ),
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        "Couldn't load transactions",
                        style: TextStyle(
                          color: AppColors.surface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
