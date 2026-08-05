import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/presentation/screen/topup_screen.dart';
import 'package:fintech_wallet/shared/widgets/balance_overview_scaffold.dart';
import 'package:fintech_wallet/shared/widgets/custom_card.dart';
import 'package:fintech_wallet/shared/widgets/custome_quick_actions_item.dart';
import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BalanceOverviewScaffold(
      headerTitle: 'My Walllet',
      headerTitleFontSize: 25,
      balanceCard: const CustomCard(
        balanceType: 'Nova Pay Wallet',
        cardType: 'Visa',
        cardNumber: '**** **** **** 1234',
        totalBalance: 12450.75,
        availableBalance: 9850.20,
        pendingBalance: 2600.55,
      ),
      quickActions: [
        CustomMenuItem(
          icon: Icons.add,
          iconColor: AppColors.primary,
          itemText: 'Top up',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TopUpScreen()),
          ),
        ),
        CustomMenuItem(
          icon: Icons.arrow_downward,
          iconColor: AppColors.primary,
          itemText: 'Withdraw',
        ),
        CustomMenuItem(
          icon: Icons.credit_card,
          iconColor: AppColors.primary,
          itemText: 'Card',
        ),
        CustomMenuItem(
          icon: Icons.history,
          iconColor: AppColors.primary,
          itemText: 'History',
        ),
      ],
      sectionTitle: 'Transaction History',
    );
  }
}
