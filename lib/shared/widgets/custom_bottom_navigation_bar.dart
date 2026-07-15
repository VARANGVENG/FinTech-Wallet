import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build navigation bar UI here
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(icon: Icons.home_outlined, label: 'Home', index: 0),
          _buildItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            index: 1,
          ),
          GestureDetector(
            onTap: () => onTap(2),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4A6CF7),
              ),
              child: Icon(Icons.add, size: 36, color: Colors.white),
            ),
          ),
          _buildItem(icon: Icons.compare_arrows, label: 'Transfer', index: 3),
          _buildItem(icon: Icons.add, label: 'Profile', index: 4),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF4A6CF7) : Colors.white70,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF4A6CF7) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
