import 'package:fintech_wallet/features/dashboard/presentation/screen/home_dashboard_screen.dart';
import 'package:fintech_wallet/features/profile/presentation/screen/profile_screen.dart';
import 'package:fintech_wallet/features/transfer/presentation/screen/transfer_screen.dart';
import 'package:fintech_wallet/features/wallet/presentation/screen/wallet_screen.dart';
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
  bool _isNavVisible = true;
  late final PageController _pageController;

  // Dense index scheme, no reserved/dead slot: 0: Home, 1: Wallet,
  // 2: Transfer, 3: Profile. The center "+" button is purely a floating
  // visual element (see CustomBottomNavigation) — it never occupies a
  // page index, so swiping never drags across a blank placeholder.
  static const List<Widget> _pages = [
    HomeDashboardScreen(),
    WalletScreen(),
    TransferScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called by tapping a bottom-nav button — animates the swipe rather
  /// than jumping instantly, so tapping and swiping feel like the same
  /// underlying motion, not two different transition styles.
  void changePage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Called by `PageView` itself whenever a swipe settles on a new page —
  /// this is what keeps the bottom nav's highlighted tab in sync with
  /// whatever you've swiped to, not just what you've tapped.
  void _handlePageChanged(int index) {
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
      body: NotificationListener<UserScrollNotification>(
        onNotification: _handleScrollNotification,
        child: PageView(
          controller: _pageController,
          onPageChanged: _handlePageChanged,
          children: _pages,
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