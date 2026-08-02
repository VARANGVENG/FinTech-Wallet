import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/core/mock/mock_transaction_history.dart';
import 'package:fintech_wallet/shared/widgets/custom_card.dart';
import 'package:fintech_wallet/shared/widgets/custom_transaction_history_item.dart';
import 'package:fintech_wallet/shared/widgets/custome_quick_actions_item.dart';
import 'package:flutter/material.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.background),
      body: Container(
        width: double.infinity,

        // height: 200,
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 25),
                  SizedBox(width: 10),
                  Text(
                    'Hello, Alex',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(19, 230, 221, 221),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    child: Icon(Icons.notifications, color: AppColors.surface),
                  ),

                  // ClipOval(
                  //   child: Image.asset(
                  //     'assets/images/profile.png',
                  //     width: 100,
                  //     height: 100,
                  //     fit: BoxFit.cover,
                  //   ),
                  // ),
                ],
              ),
              SizedBox(height: 25),
              CustomCard(
                balanceType: 'Total Balance',
                totalBalance: 12450.75,
                availableBalance: 9850.20,
                pendingBalance: 2600.55,
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CustomMenuItem(
                    icon: Icons.add,
                    iconColor: AppColors.primary,
                    itemText: 'Top up',
                  ),
                  CustomMenuItem(
                    icon: Icons.call_made,
                    iconColor: AppColors.primary,
                    itemText: 'Transfer',
                  ),
                  CustomMenuItem(
                    icon: Icons.qr_code_scanner,
                    iconColor: AppColors.primary,
                    itemText: 'Scan',
                  ),
                  CustomMenuItem(
                    icon: Icons.more_horiz,
                    iconColor: AppColors.primary,
                    itemText: 'More',
                  ),
                ],
              ),
              SizedBox(height: 17),
              Row(
                children: [
                  Text(
                    'Recent Activity',

                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 7, 143, 255),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1B2338).withOpacity(0.26),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListView.separated(
                    // shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactionHistory.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 4,
                      indent: 10,
                      endIndent: 30,
                      thickness: 0,
                    ),
                    itemBuilder: (context, index) {
                      return CustomTransactionHistoryItem(
                        transaction: transactionHistory[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
