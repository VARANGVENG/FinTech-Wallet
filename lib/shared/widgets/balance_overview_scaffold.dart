import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/core/mock/mock_transaction_history.dart';
import 'package:fintech_wallet/shared/widgets/custom_transaction_history_item.dart';
import 'package:flutter/material.dart';

/// Shared page shell for Dashboard and Wallet — both screens are the same
/// "avatar/title + notification bell, balance card, quick actions,
/// section header, scrollable transaction list" layout with different data.
/// Each caller supplies the four things that actually differ; everything
/// else (background, spacing, the transaction list itself) lives here once.
class BalanceOverviewScaffold extends StatelessWidget {
  final Widget? headerLeading;
  final String headerTitle;
  final double? headerTitleFontSize;
  final Widget balanceCard;
  final List<Widget> quickActions;
  final String sectionTitle;

  const BalanceOverviewScaffold({
    super.key,
    this.headerLeading,
    required this.headerTitle,
    this.headerTitleFontSize,
    required this.balanceCard,
    required this.quickActions,
    required this.sectionTitle,
  });

  @override
  Widget build(BuildContext context) {
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
                  const Spacer(),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(19, 230, 221, 221),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    child: Icon(Icons.notifications, color: AppColors.surface),
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
                  Text(
                    'See all',
                    style: TextStyle(color: const Color.fromARGB(255, 7, 143, 255)),
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
                  child: ListView.separated(
                    itemCount: transactionHistory.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 4,
                      indent: 10,
                      endIndent: 30,
                      thickness: 0,
                    ),
                    itemBuilder: (context, index) => CustomTransactionHistoryItem(
                      transaction: transactionHistory[index],
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