import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/shared/utils/number_extensions.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String balanceType;
  final double totalBalance;
  final double availableBalance;
  final double pendingBalance;
  final String? cardNumber;
  final String? cardType;
  const CustomCard({
    super.key,
    required this.balanceType,
    required this.totalBalance,
    required this.availableBalance,
    required this.pendingBalance,
    this.cardNumber,
    this.cardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  balanceType,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.surface,
                  ),
                ),
                Spacer(),
                if (cardType != null)
                  Text(
                    cardType!,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
              ],
            ),
            if (cardNumber != null)
              Text(
                cardNumber!,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            Text(
              totalBalance.toCurrency(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 35,
                color: AppColors.surface,
              ),
            ),
            Spacer(),
            Row(
              children: [
                Text('Available', style: TextStyle(color: AppColors.surface)),
                SizedBox(width: 10),
                Text(
                  availableBalance.toCurrency(),
                  style: TextStyle(color: AppColors.surface),
                ),
                Spacer(),
                Text('Pending', style: TextStyle(color: AppColors.surface)),
                SizedBox(width: 10),
                Text(
                  pendingBalance.toCurrency(),
                  style: TextStyle(color: AppColors.surface),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
