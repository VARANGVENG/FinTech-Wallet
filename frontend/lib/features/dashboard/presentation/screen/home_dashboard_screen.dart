import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/settings/presentation/screen/settings_screen.dart';
import 'package:fintech_wallet/features/topup/presentation/screen/topup_screen.dart';
import 'package:fintech_wallet/features/transfer/presentation/screen/transfer_screen.dart';
import 'package:fintech_wallet/shared/widgets/balance_overview_scaffold.dart';
import 'package:fintech_wallet/shared/widgets/custom_card.dart';
import 'package:fintech_wallet/shared/widgets/custome_quick_actions_item.dart';
import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboardScreen> with AutomaticKeepAliveClientMixin{
   

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BalanceOverviewScaffold(
      headerLeading: const CircleAvatar(radius: 25),
      headerTitle: 'Hello, Alex',
      onHeaderTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SettingsScreen()),
      ),
      balanceCard: const CustomCard(
        balanceType: 'Total Balance',
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
          icon: Icons.call_made,
          iconColor: AppColors.primary,
          itemText: 'Transfer',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransferScreen()),
          ),
        ),
        const CustomMenuItem(
          icon: Icons.qr_code_scanner,
          iconColor: AppColors.primary,
          itemText: 'Scan',
        ),
        const CustomMenuItem(
          icon: Icons.more_horiz,
          iconColor: AppColors.primary,
          itemText: 'More',
        ),
      ],
      sectionTitle: 'Recent Activity',
    );
  }
}
