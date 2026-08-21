import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:fintech_wallet/features/settings/presentation/screen/settings_screen.dart';
import 'package:fintech_wallet/features/topup/presentation/screen/topup_screen.dart';
import 'package:fintech_wallet/features/transfer/presentation/screen/transfer_screen.dart';
import 'package:fintech_wallet/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:fintech_wallet/shared/widgets/balance_overview_scaffold.dart';
import 'package:fintech_wallet/shared/widgets/custom_card.dart';
import 'package:fintech_wallet/shared/widgets/custome_quick_actions_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final walletAsync = ref.watch(walletProvider);
    final fullName = ref.watch(authProvider).user?.fullName;
    final firstName = fullName?.split(' ').first ?? 'there';

    return BalanceOverviewScaffold(
      headerLeading: const CircleAvatar(radius: 25),
      headerTitle: 'Hello, $firstName',
      onHeaderTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SettingsScreen()),
      ),
      balanceCard: walletAsync.when(
        data: (wallet) => CustomCard(
          balanceType: 'Total Balance',
          totalBalance: wallet.balance,
          availableBalance: wallet.balance,
          pendingBalance: 0.0,
        ),
        loading: () => const SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.surface),
          ),
        ),
        error: (error, _) => const SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'Unable to load wallet',
              style: TextStyle(color: AppColors.surface),
            ),
          ),
        ),
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
