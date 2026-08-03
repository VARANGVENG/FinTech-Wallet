import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onActionTap,
  });

  /// Index of the currently selected tab.
  /// 0: Home, 1: Wallet, 3: Transfer, 4: Profile (2 is reserved for the
  /// center action button and is never "selected").
  final int currentIndex;

  /// Called with the tapped tab index (0, 1, 3, or 4).
  final ValueChanged<int> onTap;

  /// Called when the center circular "+" button is tapped.
  final VoidCallback? onActionTap;

  static const Color _barColor = Color(0xFF14141C);
  static const Color _activeColor = Color(0xFF4C7CFF);
  static const Color _inactiveColor = Color(0xFF8A8D9F);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Pill-shaped bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: _barColor,
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          selected: currentIndex == 0,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: () => onTap(0),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.crop_square_rounded,
                          label: 'Wallet',
                          selected: currentIndex == 1,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: () => onTap(1),
                        ),
                      ),
                      // Empty space reserved for the floating center button.
                      // const Expanded(child: SizedBox()),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.compare_arrows_rounded,
                          label: 'Transfer',
                          selected: currentIndex == 3,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: () => onTap(3),
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          selected: currentIndex == 4,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: () => onTap(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Raised circular action button, overlapping the top of the bar.
              // Positioned(
              //   bottom: 38,
              //   child: GestureDetector(
              //     onTap: onActionTap,
              //     child: Container(
              //       width: 72,
              //       height: 72,
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         color: _actionColor,
              //         border: Border.all(color: _barColor, width: 6),
              //         boxShadow: [
              //           BoxShadow(
              //             color: _actionColor.withOpacity(0.5),
              //             blurRadius: 16,
              //             offset: const Offset(0, 6),
              //           ),
              //         ],
              //       ),
              //       child: const Icon(
              //         Icons.add_rounded,
              //         color: Colors.white,
              //         size: 32,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      customBorder: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
