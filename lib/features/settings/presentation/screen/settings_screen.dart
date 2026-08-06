import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/settings/presentation/provider/settings_provider.dart';
import 'package:fintech_wallet/features/settings/presentation/widget/settings_switch_tile.dart';

import 'package:fintech_wallet/shared/widgets/menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `ConsumerStatefulWidget`, not `ConsumerWidget` — needs `initState` to
/// trigger the one-time `loadSettings()` call, same reason
/// `TopUpScreen`/`TransferScreen` are stateful despite holding no local
/// fields of their own.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _SectionHeader('PREFERENCES'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  SettingsSwitchTile(
                    icon: Icons.notifications_outlined,
                    label: 'Push Notifications',
                    subtitle: 'Receive app notifications',
                    value: settings.pushNotifications,
                    onChanged: notifier.setPushNotifications,
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  SettingsSwitchTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Transaction Alerts',
                    subtitle: 'Notify on every transaction',
                    value: settings.transactionAlerts,
                    onChanged: notifier.setTransactionAlerts,
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  SettingsSwitchTile(
                    icon: Icons.fingerprint,
                    label: 'Biometric Login',
                    subtitle: 'Use Face ID or Touch ID',
                    value: settings.biometricLogin,
                    onChanged: notifier.setBiometricLogin,
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  SettingsSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    subtitle: 'Always on in this version',
                    value: settings.darkMode,
                    onChanged: notifier.setDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('SECURITY'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const MenuTile(
                title: 'Change PIN',
                icon: Icons.dialpad_outlined,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const MenuTile(
                title: 'Change Password',
                icon: Icons.lock_outline,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const MenuTile(
                title: 'Two-Factor Authentication',
                icon: Icons.shield_outlined,
                trailing: 'Off',
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('APP'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const MenuTile(
                title: 'App Version',
                icon: Icons.info_outline,
                trailing: '1.0.0',
                showChevron: false,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const MenuTile(
                title: 'About NovaPay',
                icon: Icons.bolt_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
