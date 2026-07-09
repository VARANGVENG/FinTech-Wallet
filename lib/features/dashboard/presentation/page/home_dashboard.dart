import 'package:fintech_wallet/app/constants.dart';
import 'package:fintech_wallet/features/authentication/presentation/pages/login_page.dart';
import 'package:fintech_wallet/features/authentication/presentation/pages/register_page.dart';
import 'package:fintech_wallet/shared/widgets/custome_menu_item.dart';
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
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              // InkWell(
              //   borderRadius: BorderRadius.circular(100),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => LoginPage()),
              //     );
              //   },
              // ),
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
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 170,
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
                          Text(
                            'Total Balance',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.surface,
                            ),
                          ),
                          Text(
                            '\$12,450.75,',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 35,
                              color: AppColors.surface,
                            ),
                          ),
                          Spacer(),
                          Row(
                            children: [
                              Text(
                                'Available',
                                style: TextStyle(color: AppColors.surface),
                              ),
                              SizedBox(width: 10),
                              Text(
                                '\$9,850.20',
                                style: TextStyle(color: AppColors.surface),
                              ),
                              Spacer(),
                              Text(
                                'Pending',
                                style: TextStyle(color: AppColors.surface),
                              ),
                              SizedBox(width: 10),
                              Text(
                                '\$2600.55',
                                style: TextStyle(color: AppColors.surface),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
              
            ],
          ),
        ),
      ),
    );
  }
}
