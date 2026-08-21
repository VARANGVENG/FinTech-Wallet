import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/presentation/screen/topup_screen.dart';
import 'package:fintech_wallet/shared/widgets/balance_overview_scaffold.dart';
import 'package:fintech_wallet/shared/widgets/custom_card.dart';
import 'package:fintech_wallet/shared/widgets/custome_quick_actions_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final walletAsync = ref.watch(walletProvider);

    return BalanceOverviewScaffold(
      headerTitle: 'My Walllet',
      headerTitleFontSize: 25,
      balanceCard: walletAsync.when(
        data: (wallet) => CustomCard(
          balanceType: wallet.name,
          cardType: 'Visa',
          cardNumber: '**** **** **** 1234',
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