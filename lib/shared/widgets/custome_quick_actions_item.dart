import 'package:fintech_wallet/app/constants.dart';
import 'package:flutter/material.dart';

class CustomMenuItem extends StatelessWidget {
  final String itemText;
  final IconData icon;
  final Color? iconColor;
  const CustomMenuItem({
    super.key,
    required this.itemText,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color.fromARGB(8, 230, 221, 221),
          border: Border.all(color: const Color.fromARGB(31, 255, 255, 255)),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, fontWeight: FontWeight.w900),
            Text(
              itemText,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.surface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
