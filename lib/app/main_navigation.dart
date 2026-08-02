import 'package:fintech_wallet/features/dashboard/presentation/page/home_dashboard_page.dart';
import 'package:fintech_wallet/features/wallet/presentation/page/wallet_page.dart';
import 'package:fintech_wallet/shared/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  late final List<Widget> page;
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();

    // Index scheme matches CustomBottomNavigation:
    // 0: Home, 1: Wallet, 2: (center action button, skipped), 3: Transfer, 4: Profile.
    page = [
      const HomeDashboard(), // 0: Home
      const WalletPage(),
      // const SizedBox.shrink(), // 2: unused (center "+" button)
      const _PlaceholderPage(title: 'Transfer'), // 3: Transfer
      const _PlaceholderPage(title: 'Profile'), // 4: Profile
    ];
  }

  void changePage(int index) {
    if (index == 2) {
      // Center "+" button — handle its action separately, don't navigate.
      return;
    }
    setState(() {
      currentIndex = index;
    });
  }

  bool _handleScrollNotification(UserScrollNotification notification) {
    final direction = notification.direction;

    if (direction == ScrollDirection.reverse && _isNavVisible) {
      setState(() => _isNavVisible = false);
    } else if (direction == ScrollDirection.forward && !_isNavVisible) {
      setState(() => _isNavVisible = true);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TweenAnimationBuilder<double>(
        key: ValueKey(currentIndex),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(microseconds: 200),
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: NotificationListener<UserScrollNotification>(
          onNotification: _handleScrollNotification,
          child: IndexedStack(index: currentIndex, children: page),
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: Duration(milliseconds: _isNavVisible ? 480 : 300),
        curve: _isNavVisible ? Curves.easeOutCubic : Curves.easeIn,
        offset: _isNavVisible ? Offset.zero : const Offset(0, 2),
        child: CustomBottomNavigation(
          currentIndex: currentIndex,
          onTap: changePage,
          onActionTap: () {
            // TODO: wire up the center "+" button.
          },
        ),
      ),
    );
  }
}

/// Temporary placeholder so the app doesn't crash while real pages
/// for Wallet / Transfer / Profile are still being built.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFF0B0B10),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}
