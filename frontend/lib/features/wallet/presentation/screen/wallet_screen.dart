import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/topup/presentation/screen/topup_screen.dart';
import 'package:fintech_wallet/features/wallet/domain/entities/wallet.dart';
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
  String? _selectedCurrency;
  @override
  bool get wantKeepAlive => true;

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
    BuildContext context,
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

    if (selected == null || !context.mounted) return;
    setState(() => _selectedCurrency = selected);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final walletsAsync = ref.watch(walletsProvider);

    return BalanceOverviewScaffold(
      headerTitle: 'My Walllet',
      headerTitleFontSize: 25,

      walletCurrency: walletsAsync.valueOrNull != null
          ? _resolveSelected(walletsAsync.value!).currency
          : null,
      balanceCard: walletsAsync.when(
        data: (wallets) {
          final selected = _resolveSelected(wallets);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wallets.length > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _handleCurrencyTap(
                        context,
                        wallets,
                        selected.currency,
                      ),
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
                const SizedBox(height: 8),
              ],
              CustomCard(
                balanceType: selected.name,
                cardType: 'Visa',
                cardNumber: '**** **** **** 1234',
                totalBalance: selected.balance,
                availableBalance: selected.balance,
                pendingBalance: 0.0,
                currency: selected.currency,
              ),
            ],
          );
        },
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
